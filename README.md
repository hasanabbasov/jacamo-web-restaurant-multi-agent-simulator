# 🍽️ JaCaMo Restaurant Multi-Agent Simulation

## Progress Report

**Project:** Autonomous Restaurant Simulation  
**Platform:** JaCaMo (Jason + CArtAgO + Moise)  
**Containerization:** Docker + Nginx  
**Status:** ✅ Active Development

---

## 📋 1. Project Summary

This project is a multi-agent system where AI-powered autonomous agents communicate with each other to simulate a restaurant business.

### 🎯 Objective
- Demonstrate Multi-Agent Systems (MAS) concepts in a practical scenario
- Showcase the integrated use of JaCaMo platform (Jason, CArtAgO, Moise)
- Provide easy deployment with Docker containerization
- Offer real-time agent interaction through web interface

### 🏆 Key Features
| Feature | Description |
|---------|-------------|
| **Autonomous Agents** | Waiter, Cook, Cashier, Customer |
| **Real-time Web UI** | Order and queue monitoring |
| **Agent Communication** | ACL messaging protocol |
| **Artifact System** | Shared environment objects |
| **Organization** | Role and task distribution |

---

## 🚀 2. Getting Started

### Requirements
- Docker Desktop
- Port 8080 must be available

### Launch Command
```bash
cd jacamo-web-demo-marketplace-master
docker-compose up --build
```

### Access URLs
| URL | Page |
|-----|------|
| http://localhost:8080/simulation.html | Visual Simulation |
| http://localhost:8080/agents.html | Agent List |
| http://localhost:8080/workspaces.html | Environment |
| http://localhost:8080/oe.html | Organization |
| http://localhost:8080/agent_new.html | Create New Agent |

### View Logs
```bash
docker logs -f jacamo-web-demo-restaurant-master
```

### Stop
```bash
docker-compose down
```

---

## 🏗️ 3. Project Structure

```
jacamo-web-demo-marketplace-master/
├── src/
│   ├── agt/                    # Agent Code (.asl)
│   │   ├── waiter.asl          # Waiter agent
│   │   ├── cook.asl            # Cook agent
│   │   ├── cashier.asl         # Cashier agent
│   │   └── customer.asl        # Customer agent
│   │
│   ├── env/restaurant/         # Artifacts (Java)
│   │   ├── TableManager.java   # Table management
│   │   ├── OrderBoard.java     # Order tracking
│   │   ├── Kitchen.java        # Kitchen operations
│   │   └── CashRegister.java   # Cash and pricing
│   │
│   └── org/                    # Organization
│       └── restaurant.xml      # Role and group definitions
│
├── restaurant.jcm              # JaCaMo configuration
├── simulation.html             # Web interface
├── docker-compose.yml          # Container orchestration
├── Dockerfile                  # JaCaMo image definition
└── nginx.conf                  # Reverse proxy
```

---

## 🤖 4. Agent Classes (src/agt/)

### 4.1 Waiter Agent (`waiter.asl`)
**Role:** Coordinator - Manages entire flow

| Plan | Trigger | Action |
|------|---------|--------|
| `+!takeOrder(C, F)` | When order arrives | Record to OrderBoard, send to Cook |
| `+foodReady(C, F)` | When food is ready | Serve to customer |
| `+!getBill(C)` | When bill is requested | Calculate from CashRegister |

**Artifacts Used:** `TableManager`, `OrderBoard`, `CashRegister`

### 4.2 Cook Agent (`cook.asl`)
**Role:** Producer - Prepares food

| Plan | Trigger | Action |
|------|---------|--------|
| `+!prepareFood(C, F)` | Order from Waiter | Wait cooking time, notify when ready |

**Cooking Times:**
- 🍕 Pizza: 15 seconds
- 🍔 Burger: 13 seconds
- 🥗 Salad: 12 seconds
- 🍝 Pasta: 14 seconds
- 🥩 Steak: 17 seconds

### 4.3 Cashier Agent (`cashier.asl`)
**Role:** Finance - Processes payments

| Plan | Action |
|------|--------|
| `+!processPayment(C, A)` | Accept payment, update cash register |

### 4.4 Customer Agent (`customer.asl`)
**Role:** Simulator - Orders, eats, pays

| Plan | Action |
|------|--------|
| `+!init` | Join workspace, focus on artifacts |
| `+orderReceived` | Receive order confirmation |
| `+foodServed` | Receive food, eat, request bill |

---

## 🛠️ 5. Artifact Classes (src/env/restaurant/)

### 5.1 TableManager.java
**Purpose:** Table reservation and status

| Operation | Parameter | Result |
|-----------|-----------|--------|
| `assignTable(customer)` | Customer name | Assigns table, `tableAssigned` signal |
| `freeTable(customer)` | Customer name | Frees the table |

**Observable Properties:**
- `tableStatus(id, status)` - Status of each table

### 5.2 OrderBoard.java
**Purpose:** Order tracking board (Provides data to Frontend)

| Operation | Action |
|-----------|--------|
| `recordOrder(c, f)` | Record new order |
| `startCooking(f)` | Cooking started |
| `finishCooking(f)` | Cooking finished |
| `deliverFood(c, f)` | Service completed |

**Observable Properties:**
- `pendingOrders` - Number of pending orders
- `cookingOrders` - Number of cooking orders
- `completedOrders` - Number of completed orders
- `currentStatus` - Last status message

### 5.3 Kitchen.java
**Purpose:** Kitchen capacity and stove management

| Operation | Action |
|-----------|--------|
| `useOven()` | Occupy the stove |
| `releaseOven()` | Release the stove |

### 5.4 CashRegister.java
**Purpose:** Pricing and payment

| Operation | Action |
|-----------|--------|
| `addToOrder(c, f)` | Add food to customer's bill |
| `calculateBill(c)` | Calculate total bill |
| `processPayment(c, a)` | Process payment |

**Price List:**
- Pizza: $25
- Burger: $18
- Salad: $12
- Pasta: $20
- Steak: $45

---

## 🏛️ 6. Organization (src/org/restaurant.xml)

Moise organization structure defines the social relationships, roles, and tasks of agents. This XML file consists of three main sections.

### 6.1 Structural Specification

Defines agents' roles and groups.

**Roles:**
| Role ID | Description | Min-Max |
|---------|-------------|---------|
| `rcustomer` | Customer role | 1-10 |
| `rwaiter` | Waiter role | 1-3 |
| `rcook` | Cook role | 1-2 |
| `rcashier` | Cashier role | 1-1 |

**Communication Links:**
```
rcustomer ↔ rwaiter   (order, service)
rwaiter   ↔ rcook     (kitchen coordination)
rwaiter   ↔ rcashier  (bill)
rcustomer ↔ rcashier  (payment)
```

### 6.2 Functional Specification

Defines service flow (scheme) and missions.

**Service Flow (Sequential):**
```
seatCustomer → takeOrder → cookFood → serveFood → takePayment
```

**Missions:**
| Mission | Role | Goals |
|---------|------|-------|
| `mCustomer` | rcustomer | seatCustomer, takePayment |
| `mWaiter` | rwaiter | takeOrder, serveFood |
| `mCook` | rcook | cookFood |
| `mCashier` | rcashier | takePayment |

### 6.3 Normative Specification

Defines mandatory obligations for roles.

| Norm | Role | Obligation |
|------|------|------------|
| `normWaiterOrder` | rwaiter | Must take orders |
| `normCookFood` | rcook | Must prepare food |
| `normCashierPayment` | rcashier | Must accept payment |
| `normCustomerPay` | rcustomer | Must make payment |

---

## 🔄 7. Communication Flow

```
┌─────────────┐     (1) takeOrder      ┌─────────────┐
│  Customer   │ ──────────────────────▶ │   Waiter    │
└─────────────┘                        └──────┬──────┘
                                              │
                    (2) prepareFood           │
                    ┌─────────────────────────┘
                    ▼
              ┌─────────────┐
              │    Cook     │ ◄── (3) .wait(cookingTime)
              └──────┬──────┘
                     │
                     │ (4) foodReady
                     ▼
              ┌─────────────┐
              │   Waiter    │
              └──────┬──────┘
                     │
                     │ (5) foodServed
                     ▼
              ┌─────────────┐     (6) getBill      ┌─────────────┐
              │  Customer   │ ──────────────────▶  │   Waiter    │
              └─────────────┘                      └──────┬──────┘
                                                          │
                     ┌────────────────────────────────────┘
                     │ (7) processPayment
                     ▼
              ┌─────────────┐
              │   Cashier   │
              └─────────────┘
```

---

## 🧪 7. Customer4 Example (Runtime Agent Creation)

This section demonstrates creating and configuring a new customer agent at runtime.

### Step 1: Create Agent
```
http://localhost:8080/agent_new.html
→ Type "customer4", press Enter
```

### Step 2: Go to Agent Page
```
http://localhost:8080/agent.html?agent=customer4
```

### Step 3: Load ASL Code

Click the `customer4.asl` link at the bottom of the page and paste the following code in the editor:

```prolog
// ═══════════════════════════════════════════════════════
// Customer4 Agent - Runtime Generated
// ═══════════════════════════════════════════════════════

// Initial Beliefs
preferredFood(pasta).
myBudget(100).

// Initial Goal
!init.

// ═══════════════════════════════════════════════════════
// INIT - Agent initialization
// ═══════════════════════════════════════════════════════
+!init <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 [CUSTOMER4] Hello! I am a new customer.");
    .print("🧑 [CUSTOMER4] Preference: pasta, Budget: $100");
    .print("═══════════════════════════════════════════════════════");
    
    // Join workspace
    joinWorkspace("diningRoom", WspId);
    .print("🧑 [CUSTOMER4] Joined diningRoom workspace.");
    
    // Focus on artifacts
    lookupArtifact("orderBoard", OrderId);
    focus(OrderId);
    lookupArtifact("tables", TablesId);
    focus(TablesId);
    .print("🧑 [CUSTOMER4] Focused on artifacts.");
    
    .print("🧑 [CUSTOMER4] ✅ Ready! You can order from simulation.html.").

// ═══════════════════════════════════════════════════════
// Order and Service Plans
// ═══════════════════════════════════════════════════════
+orderReceived(Food)[source(S)] <-
    .print("🧑 [CUSTOMER4] ✓ My order confirmed: ", Food);
    .print("🧑 [CUSTOMER4] Waiting for my food...").

+foodServed(Food)[source(S)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 [CUSTOMER4] 🍽️ My food arrived: ", Food);
    .print("🧑 [CUSTOMER4] Eating...");
    .print("═══════════════════════════════════════════════════════");
    .wait(3000);
    .print("🧑 [CUSTOMER4] Finished my meal! 😋");
    !askForBill.

+!askForBill <-
    .print("🧑 [CUSTOMER4] 💰 Requesting bill...");
    .send(waiter, achieve, getBill(customer4)).

+billReady(Amount)[source(S)] <-
    .print("🧑 [CUSTOMER4] Bill: $", Amount);
    .print("🧑 [CUSTOMER4] Making payment...");
    .send(cashier, achieve, processPayment(customer4, Amount)).

+paymentComplete[source(S)] <-
    .print("═══════════════════════════════════════════════════════");
    .print("🧑 [CUSTOMER4] ✅ Payment complete! Thank you!");
    .print("═══════════════════════════════════════════════════════").

// Templates
{ include("$jacamoJar/templates/common-cartago.asl") }
{ include("$jacamoJar/templates/common-moise.asl") }
```

### Step 4: Save and Start
1. Click **Save** button
2. Type `!init` in the Command box at top and press Enter

### Step 5: Test
1. Go to http://localhost:8080/simulation.html
2. `customer4` will appear in "Select Customer" dropdown
3. Place an order and watch the flow in terminal:
   ```bash
   docker logs -f jacamo-web-demo-restaurant-master
   ```

### Permanent Addition (Optional)
You can add to `restaurant.jcm` file to have it automatically created when system restarts:

```
agent customer4 : customer.asl {
    focus: diningRoom.orderBoard
    focus: diningRoom.tables
    beliefs: preferredFood(pasta)
}
```

---

## 📊 8. Current Status and Next Steps

### ✅ Completed
- [x] Docker containerization
- [x] Nginx reverse proxy
- [x] Web simulation interface
- [x] Agent communication flow
- [x] Real-time artifact polling
- [x] Dynamic customer dropdown
- [x] Cooking times (+10 seconds)
- [x] Light theme UI redesign

### 🔄 In Progress
- [ ] Priority queue algorithm (value/time sorting)
- [ ] More detailed queue visualization
- [ ] Try Blackboard Pattern!

### 📝 Notes
- JaCaMo agents print detailed logs in terminal
- Frontend polls OrderBoard every 2 seconds
- New agents are automatically added to dropdown

---

**Report Date:** 2026-01-10  
**Project Repository:** https://github.com/hasanabbasov/jacamo-web-restaurant-multi-agent-simulator
