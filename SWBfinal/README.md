# Smart Water Billing & Monitoring System
## Enhanced Version — Role-Based Login + User Portal

---

## What's New in This Version

| Feature | Before | After |
|---|---|---|
| Login | Only admin/admin | Role-based: admin → Admin Portal, users → User Portal |
| User Registration | Not working | Full self-registration form with validation |
| User Portal | Did not exist | Complete personalized dashboard |
| Session Security | No guards | All pages protected — unauthorized users redirected |
| Logout | Redirected to login.html directly | Proper session invalidation via servlet |

---

## Project Structure

```
SBW_enhanced/
├── login.html              ← Unified Login + Register page
├── dashboard.jsp           ← ADMIN portal (protected)
├── user_dashboard.jsp      ← USER portal (protected)
├── save_bill.jsp           ← Admin billing save (protected)
├── schema.sql              ← Run this first in MySQL
├── src/com/water/
│   ├── AuthServlet.java    ← Role-based login (admin/user)
│   ├── RegisterServlet.java← User self-registration
│   ├── LogoutServlet.java  ← Session invalidation
│   ├── UsageServlet.java   ← Billing data servlet
│   ├── DBConnection.java   ← MySQL connection utility
│   └── PasswordUtil.java   ← Password check utility
├── WEB-INF/
│   ├── web.xml             ← All servlet mappings
│   └── lib/
│       └── mysql-connector-j-8.0.33.jar
└── js/
    └── script.js
```

---

## Setup Instructions

### Step 1 — MySQL Setup
```sql
-- Open MySQL Workbench or terminal and run:
source schema.sql;
```
This creates the `water_system` database, `users` table, `usage_records` table and inserts sample data.

### Step 2 — Deploy to Apache Tomcat
1. Copy the project folder into `webapps/` of your Tomcat installation
2. Compile Java sources:
```
javac -cp WEB-INF/lib/mysql-connector-j-8.0.33.jar:path/to/servlet-api.jar \
      -d WEB-INF/classes \
      src/com/water/*.java
```
3. Start Tomcat and open: `http://localhost:8080/SBW_final/`

---

## Login Credentials

### Admin Login
| Field | Value |
|---|---|
| Username | `admin` |
| Password | `admin` |
| Redirects to | `dashboard.jsp` (Admin Portal) |

### Sample User Logins (from schema.sql seed data)
| Username | Password | Name |
|---|---|---|
| `saipranay` | `user123` | Sai Pranay Reddy |
| `vardhan` | `user123` | Vardhan Kumar |
| `geeta` | `user123` | Geeta Sharma |
| `vaishnavi` | `user123` | Vaishnavi Nair |

### New User Registration
- Click **Register** tab on the login page
- Fill in all fields (name, email, username, phone, address, password)
- On success, redirected to Login with a success message

---

## User Portal Features

- **My Dashboard** — Stats cards, usage trend chart, last bill, alerts
- **My Bills** — Full billing history table with Pay Now button
- **Usage Analytics** — Weekly bar chart, monthly doughnut chart, averages
- **My Profile** — Shows meter number, email, phone, address
- **Conservation Tips** — Water-saving tips, system status, notices

## Admin Portal Features (unchanged + improved)
- Role-guarded (redirects non-admins)
- Dashboard, Create Bill, History, Tips & Leakage, Logs, Themes

---

## Database Configuration
Edit `src/com/water/DBConnection.java` to change DB credentials:
```java
con = DriverManager.getConnection(
    "jdbc:mysql://localhost:3306/water_system?useSSL=false&serverTimezone=UTC",
    "root",      // ← your MySQL username
    "manager"    // ← your MySQL password
);
```
