<%@ page import="java.sql.*, java.util.Date, java.text.SimpleDateFormat, com.water.DBConnection" %>
<%
    // Role guard
    HttpSession s = request.getSession(false);
    if(s == null || s.getAttribute("role") == null || !s.getAttribute("role").equals("USER")) {
        response.sendRedirect("login.html");
        return;
    }

    // Safe session reads — never cast directly, always check for null first
    String displayName = s.getAttribute("displayName") != null ? (String) s.getAttribute("displayName") : "User";
    String username    = s.getAttribute("user")        != null ? (String) s.getAttribute("user")        : "";
    int userId = 0;
    Object uidObj = s.getAttribute("userId");
    if(uidObj != null) {
        try { userId = (Integer) uidObj; } catch(Exception ex) { userId = 0; }
    }

    String logTime = new SimpleDateFormat("hh:mm:ss a").format(new Date());
    String logDate = new SimpleDateFormat("dd MMM yyyy").format(new Date());

    // Fetch user data
    int myTotalBills = 0, myTotalUsage = 0, myTotalAmount = 0;
    String meterNo = "N/A", phone = "", address = "", email = "";
    String lastBillDate = "-", lastBillAmount = "-";
    String dbError = "";

    try {
        Connection con = DBConnection.getConnection();

        if(con == null) {
            dbError = "Database connection failed. Check MySQL is running and DBConnection.java has the correct password.";
        } else {
            // User info — fetch by userId if available, else by username
            PreparedStatement psU;
            if(userId > 0) {
                psU = con.prepareStatement("SELECT email, phone, address, meter_no FROM users WHERE id = ?");
                psU.setInt(1, userId);
            } else {
                psU = con.prepareStatement("SELECT email, phone, address, meter_no FROM users WHERE username = ?");
                psU.setString(1, username);
            }
            ResultSet rsU = psU.executeQuery();
            if(rsU.next()) {
                email   = rsU.getString("email")   != null ? rsU.getString("email")   : "";
                phone   = rsU.getString("phone")   != null ? rsU.getString("phone")   : "";
                address = rsU.getString("address") != null ? rsU.getString("address") : "";
                meterNo = rsU.getString("meter_no")!= null ? rsU.getString("meter_no"): "N/A";
            }

            // Billing stats for this user
            PreparedStatement psB = con.prepareStatement(
                "SELECT COUNT(*), COALESCE(SUM(units),0), COALESCE(SUM(bill_amount),0) FROM usage_records WHERE customer_name = ?");
            psB.setString(1, username);
            ResultSet rsB = psB.executeQuery();
            if(rsB.next()) {
                myTotalBills  = rsB.getInt(1);
                myTotalUsage  = rsB.getInt(2);
                myTotalAmount = rsB.getInt(3);
            }

            // Last bill
            PreparedStatement psL = con.prepareStatement(
                "SELECT bill_amount, bill_date FROM usage_records WHERE customer_name = ? ORDER BY id DESC LIMIT 1");
            psL.setString(1, username);
            ResultSet rsL = psL.executeQuery();
            if(rsL.next()) {
                lastBillAmount = "Rs. " + rsL.getInt("bill_amount");
                lastBillDate   = rsL.getString("bill_date") != null ? rsL.getString("bill_date") : "-";
            }

            con.close();
        }
    } catch(Exception e) {
        dbError = "DB Error: " + e.getMessage();
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>My Water Portal - <%= displayName %></title>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        :root {
            --primary: #0ea5e9;
            --sidebar-grad: linear-gradient(180deg, #0f172a 0%, #1e293b 100%);
            --bg: #f1f5f9;
            --card-bg: #ffffff;
            --text: #1e293b;
            --success: #10b981;
            --warning: #f59e0b;
            --danger: #f43f5e;
        }
        body { margin:0; font-family:'Plus Jakarta Sans',sans-serif; background:var(--bg); display:flex; color:var(--text); }

        .sidebar {
            width: 260px; height: 100vh;
            background: var(--sidebar-grad);
            color: white; position: fixed;
            display: flex; flex-direction: column;
            justify-content: space-between; z-index:1000;
        }
        .sidebar-brand {
            padding: 28px 20px 10px;
            text-align: center;
        }
        .sidebar-brand .logo {
            width: 48px; height: 48px;
            background: linear-gradient(135deg, #38bdf8, #0284c7);
            border-radius: 14px;
            display: flex; align-items: center; justify-content: center;
            font-size: 22px; color: white; margin: 0 auto 10px;
        }
        .sidebar-brand h2 {
            font-size: 1rem; font-weight: 800;
            background: linear-gradient(to right, #38bdf8, #818cf8);
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
        }
        .user-pill {
            margin: 12px 16px 20px;
            background: rgba(255,255,255,0.06);
            border-radius: 12px; padding: 12px 14px;
            display: flex; align-items: center; gap: 10px;
        }
        .user-avatar {
            width:36px; height:36px; border-radius:50%;
            background: linear-gradient(135deg, #0ea5e9, #6366f1);
            display: flex; align-items: center; justify-content: center;
            font-weight: 800; font-size: 14px; color: white; flex-shrink:0;
        }
        .user-info .name { font-weight:700; font-size:0.85rem; color:white; }
        .user-info .role { font-size:0.7rem; color:#38bdf8; font-weight:600; text-transform:uppercase; }

        .nav-item {
            display: flex; align-items: center; gap: 12px;
            color: #94a3b8; padding: 13px 16px;
            text-decoration: none; cursor: pointer;
            transition: 0.3s; margin: 0 12px 4px;
            border-radius: 12px; font-weight: 600; font-size: 0.88rem;
        }
        .nav-item:hover, .nav-item.active {
            background: rgba(255,255,255,0.08); color: white;
        }
        .nav-item.active {
            background: var(--primary);
            box-shadow: 0 6px 15px rgba(14,165,233,0.3);
        }

        .main { margin-left: 260px; padding: 35px 40px; width: calc(100% - 260px); }

        .tab-content { display: none; animation: fadeIn 0.35s ease; }
        .tab-content.active { display: block; }
        @keyframes fadeIn { from { opacity:0; transform:translateY(8px); } to { opacity:1; transform:translateY(0); } }

        .card {
            background: var(--card-bg); padding: 24px;
            border-radius: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.06);
            margin-bottom: 22px; border: 1px solid rgba(0,0,0,0.05);
        }
        .stat-card {
            background: var(--card-bg); padding: 22px 24px;
            border-radius: 18px; box-shadow: 0 2px 10px rgba(0,0,0,0.05);
            border: 1px solid rgba(0,0,0,0.05);
        }
        .stat-card .label { font-size:0.75rem; color:#64748b; font-weight:700; text-transform:uppercase; letter-spacing:0.5px; margin-bottom:6px; }
        .stat-card .value { font-size:1.9rem; font-weight:800; }
        .stat-card .sub { font-size:0.8rem; color:#94a3b8; margin-top:4px; }

        .grid3 { display:grid; grid-template-columns:repeat(3,1fr); gap:18px; margin-bottom:24px; }
        .grid2 { display:grid; grid-template-columns:1.4fr 1fr; gap:22px; }

        table { width:100%; border-collapse:collapse; }
        th { background:rgba(0,0,0,0.02); padding:12px 14px; text-align:left; color:#64748b; font-size:0.72rem; text-transform:uppercase; letter-spacing:0.5px; }
        td { padding:14px; border-bottom:1px solid rgba(0,0,0,0.04); font-size:0.9rem; }
        tr:last-child td { border-bottom:none; }

        .badge { padding:4px 10px; border-radius:8px; font-size:0.7rem; font-weight:700; }
        .badge-paid { background:#dcfce7; color:#166534; }
        .badge-pending { background:#fef9c3; color:#854d0e; }

        .info-row { display:flex; justify-content:space-between; align-items:center; padding:12px 0; border-bottom:1px solid rgba(0,0,0,0.05); }
        .info-row:last-child { border-bottom:none; }
        .info-label { font-size:0.8rem; color:#94a3b8; font-weight:600; text-transform:uppercase; }
        .info-value { font-weight:700; font-size:0.9rem; }

        .pay-btn {
            background: var(--primary); color:white; border:none;
            padding:8px 18px; border-radius:9px; font-weight:700; font-size:0.82rem;
            cursor:pointer; transition:0.2s; font-family:inherit;
        }
        .pay-btn:hover { transform:translateY(-2px); box-shadow:0 4px 12px rgba(14,165,233,0.4); }

        .wave-bar {
            height: 8px; background:#e2e8f0; border-radius:8px; overflow:hidden;
        }
        .wave-bar-fill {
            height:100%; background:linear-gradient(to right, #38bdf8, #0284c7);
            border-radius:8px; transition:width 1s ease;
        }

        .alert-item {
            display:flex; align-items:center; gap:14px;
            padding:14px; border-radius:14px; margin-bottom:12px;
        }
        .alert-info { background:#eff6ff; border-left:4px solid #3b82f6; }
        .alert-warn { background:#fffbeb; border-left:4px solid #f59e0b; }
        .alert-ok   { background:#f0fdf4; border-left:4px solid #10b981; }

        @media print {
            .sidebar, .no-print { display:none !important; }
            .main { margin-left:0; width:100%; }
        }
    </style>
</head>
<body>

<!-- SIDEBAR -->
<div class="sidebar">
    <div>
        <div class="sidebar-brand">
            <div class="logo"><i class="fas fa-tint"></i></div>
            <h2>SMART WATER PORTAL</h2>
        </div>

        <div class="user-pill">
            <div class="user-avatar"><%= displayName.substring(0,1).toUpperCase() %></div>
            <div class="user-info">
                <div class="name"><%= displayName %></div>
                <div class="role">Resident User</div>
            </div>
        </div>

        <nav>
            <a class="nav-item active" onclick="openTab('home', this)"><i class="fas fa-th-large"></i> My Dashboard</a>
            <a class="nav-item" onclick="openTab('bills', this)"><i class="fas fa-file-invoice"></i> My Bills</a>
            <a class="nav-item" onclick="openTab('usage', this)"><i class="fas fa-chart-line"></i> Usage Analytics</a>
            <a class="nav-item" onclick="openTab('profile', this)"><i class="fas fa-user-circle"></i> My Profile</a>
            <a class="nav-item" onclick="openTab('tips', this)"><i class="fas fa-lightbulb"></i> Conservation Tips</a>
            <a class="nav-item" href="iot_coming_soon.html" style="color:#f59e0b;"><i class="fas fa-microchip"></i> IoT Monitor <span style="font-size:0.6rem;background:rgba(245,158,11,0.2);padding:2px 6px;border-radius:10px;margin-left:4px;font-weight:800;">SOON</span></a>
        </nav>
    </div>
    <a href="logout" class="nav-item"><i class="fas fa-power-off"></i> Logout</a>
</div>

<!-- MAIN CONTENT -->
<div class="main">
    <% if(!dbError.isEmpty()) { %>
    <div style="background:#fff1f2;border:1.5px solid #f43f5e;border-radius:14px;padding:16px 22px;margin-bottom:24px;display:flex;align-items:center;gap:14px;">
        <i class="fas fa-exclamation-circle" style="color:#f43f5e;font-size:20px;flex-shrink:0;"></i>
        <div>
            <div style="font-weight:800;color:#be123c;margin-bottom:3px;">Database Connection Error</div>
            <div style="font-size:0.85rem;color:#9f1239;"><%=dbError%></div>
            <div style="font-size:0.8rem;color:#9f1239;margin-top:4px;">
                Fix: Open <code>DBConnection.java</code> → update your MySQL password → recompile → restart Tomcat.
            </div>
        </div>
    </div>
    <% } %>
    <!-- Header -->
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:30px;">
        <div>
            <h1 style="font-weight:800; margin:0; font-size:1.7rem;">Welcome, <%= displayName %>!</h1>
            <p style="margin:5px 0 0 0; color:#64748b; font-size:0.9rem;">
                Meter No: <strong style="color:var(--primary)"><%= meterNo %></strong> &nbsp;|&nbsp;
                Status: <span style="color:var(--success); font-weight:700;">Active</span>
            </p>
        </div>
        <div style="text-align:right;">
            <div style="font-weight:700; color:var(--primary);"><%= logTime %></div>
            <div style="color:#94a3b8; font-size:0.82rem;"><%= logDate %></div>
        </div>
    </div>

    <!-- HOME TAB -->
    <div id="home" class="tab-content active">
        <div class="grid3">
            <div class="stat-card">
                <div class="label">Total Bills</div>
                <div class="value"><%= myTotalBills %></div>
                <div class="sub">All time records</div>
            </div>
            <div class="stat-card">
                <div class="label">Total Usage</div>
                <div class="value" style="color:var(--primary)"><%= myTotalUsage %> L</div>
                <div class="sub">Litres consumed</div>
            </div>
            <div class="stat-card">
                <div class="label">Total Amount</div>
                <div class="value" style="color:var(--success)">Rs. <%= myTotalAmount %></div>
                <div class="sub">Lifetime billing</div>
            </div>
        </div>

        <div class="grid2">
            <div>
                <div class="card">
                    <h3 style="margin:0 0 18px; font-weight:800;">Usage Trend (Last 7 Days)</h3>
                    <canvas id="myUsageChart" height="130"></canvas>
                </div>

                <div class="card">
                    <h3 style="margin:0 0 16px; font-weight:800;">Last Bill Summary</h3>
                    <div class="info-row">
                        <span class="info-label">Last Bill Amount</span>
                        <span class="info-value" style="color:var(--success)"><%= lastBillAmount %></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Billing Date</span>
                        <span class="info-value"><%= lastBillDate %></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Rate</span>
                        <span class="info-value">Rs. 2 / Litre</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Payment Status</span>
                        <span class="badge badge-pending">Pending</span>
                    </div>
                    <button class="pay-btn no-print" style="margin-top:14px; width:100%; padding:12px;" onclick="alert('Payment gateway integration coming soon!\n\nUPI: water@payments\nAmount: ' + '<%= lastBillAmount %>')">
                        <i class="fas fa-credit-card"></i> Pay Now
                    </button>
                </div>
            </div>

            <div>
                <div class="card">
                    <h3 style="margin:0 0 16px; font-weight:800;">Alerts & Notices</h3>
                    <div class="alert-item alert-ok">
                        <i class="fas fa-check-circle" style="color:#10b981; font-size:18px;"></i>
                        <div>
                            <div style="font-weight:700; font-size:0.88rem;">No Leakage Detected</div>
                            <div style="font-size:0.78rem; color:#64748b; margin-top:2px;">All systems normal</div>
                        </div>
                    </div>
                    <div class="alert-item alert-info">
                        <i class="fas fa-info-circle" style="color:#3b82f6; font-size:18px;"></i>
                        <div>
                            <div style="font-weight:700; font-size:0.88rem;">Scheduled Maintenance</div>
                            <div style="font-size:0.78rem; color:#64748b; margin-top:2px;">Mar 20 – 8AM to 12PM</div>
                        </div>
                    </div>
                    <div class="alert-item alert-warn">
                        <i class="fas fa-exclamation-triangle" style="color:#f59e0b; font-size:18px;"></i>
                        <div>
                            <div style="font-weight:700; font-size:0.88rem;">Bill Due Soon</div>
                            <div style="font-size:0.78rem; color:#64748b; margin-top:2px;">Due date: 25 Mar 2026</div>
                        </div>
                    </div>
                </div>

                <div class="card">
                    <h3 style="margin:0 0 14px; font-weight:800;">Monthly Usage Goal</h3>
                    <div style="display:flex; justify-content:space-between; font-size:0.82rem; margin-bottom:8px;">
                        <span style="color:#64748b;">Used: <strong><%= myTotalUsage %> L</strong></span>
                        <span style="color:#64748b;">Goal: <strong>1000 L</strong></span>
                    </div>
                    <div class="wave-bar">
                        <div class="wave-bar-fill" id="usageGoalBar" style="width:0%"></div>
                    </div>
                    <p style="font-size:0.78rem; color:#94a3b8; margin-top:8px;" id="goalText">Calculating...</p>
                </div>
            </div>
        </div>
    </div>

    <!-- BILLS TAB -->
    <div id="bills" class="tab-content">
        <div class="card">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:18px;">
                <h3 style="margin:0; font-weight:800;">My Billing History</h3>
                <button class="pay-btn no-print" onclick="window.print()">
                    <i class="fas fa-print"></i> Print
                </button>
            </div>
            <table id="billTable">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Date</th>
                        <th>Usage (Litres)</th>
                        <th>Amount</th>
                        <th>Status</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        try {
                            Connection conB2 = DBConnection.getConnection();
                            PreparedStatement psBill = conB2.prepareStatement(
                                "SELECT * FROM usage_records WHERE customer_name = ? ORDER BY id DESC");
                            psBill.setString(1, username);
                            ResultSet rsBill = psBill.executeQuery();
                            int rowNum = 1;
                            while(rsBill.next()) {
                    %>
                    <tr>
                        <td style="color:#94a3b8; font-size:0.8rem;">#<%= rsBill.getInt("id") %></td>
                        <td><%= rsBill.getString("bill_date") != null ? rsBill.getString("bill_date") : "-" %></td>
                        <td><strong><%= rsBill.getInt("units") %></strong> L</td>
                        <td style="color:var(--success); font-weight:700;">Rs. <%= rsBill.getInt("bill_amount") %></td>
                        <td><span class="badge badge-pending">Pending</span></td>
                        <td><button class="pay-btn" onclick="payNow(<%= rsBill.getInt("bill_amount") %>)">Pay</button></td>
                    </tr>
                    <% rowNum++; } conB2.close(); } catch(Exception e){ out.println("<tr><td colspan='6'>No records found.</td></tr>"); } %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- USAGE TAB -->
    <div id="usage" class="tab-content">
        <div class="grid2">
            <div class="card">
                <h3 style="margin:0 0 18px; font-weight:800;">Weekly Consumption</h3>
                <canvas id="weekChart" height="160"></canvas>
            </div>
            <div class="card">
                <h3 style="margin:0 0 18px; font-weight:800;">Monthly Breakdown</h3>
                <canvas id="monthChart" height="160"></canvas>
            </div>
        </div>
        <div class="card">
            <h3 style="margin:0 0 14px; font-weight:800;">Usage Insights</h3>
            <div style="display:grid; grid-template-columns:repeat(3,1fr); gap:16px;">
                <div style="background:#eff6ff; padding:18px; border-radius:14px; text-align:center;">
                    <div style="font-size:1.6rem; font-weight:800; color:#3b82f6;"><%= myTotalUsage %></div>
                    <div style="font-size:0.78rem; color:#64748b; margin-top:4px;">Total Litres Used</div>
                </div>
                <div style="background:#f0fdf4; padding:18px; border-radius:14px; text-align:center;">
                    <div style="font-size:1.6rem; font-weight:800; color:var(--success);"><%= myTotalBills > 0 ? (myTotalUsage / myTotalBills) : 0 %></div>
                    <div style="font-size:0.78rem; color:#64748b; margin-top:4px;">Avg Litres / Bill</div>
                </div>
                <div style="background:#fffbeb; padding:18px; border-radius:14px; text-align:center;">
                    <div style="font-size:1.6rem; font-weight:800; color:var(--warning);">Rs. <%= myTotalBills > 0 ? (myTotalAmount / myTotalBills) : 0 %></div>
                    <div style="font-size:0.78rem; color:#64748b; margin-top:4px;">Avg Bill Amount</div>
                </div>
            </div>
        </div>
    </div>

    <!-- PROFILE TAB -->
    <div id="profile" class="tab-content">
        <div style="max-width:600px;">
            <div class="card">
                <div style="display:flex; align-items:center; gap:20px; margin-bottom:24px;">
                    <div style="width:70px; height:70px; border-radius:20px; background:linear-gradient(135deg,#0ea5e9,#6366f1); display:flex; align-items:center; justify-content:center; font-size:28px; font-weight:800; color:white;">
                        <%= displayName.substring(0,1).toUpperCase() %>
                    </div>
                    <div>
                        <div style="font-size:1.3rem; font-weight:800;"><%= displayName %></div>
                        <div style="color:var(--primary); font-weight:600; font-size:0.85rem;">@<%= username %></div>
                        <div style="font-size:0.78rem; color:#94a3b8; margin-top:2px;">Resident User</div>
                    </div>
                </div>

                <div class="info-row">
                    <span class="info-label"><i class="fas fa-tachometer-alt"></i> &nbsp; Meter Number</span>
                    <span class="info-value" style="color:var(--primary);"><%= meterNo %></span>
                </div>
                <div class="info-row">
                    <span class="info-label"><i class="fas fa-envelope"></i> &nbsp; Email</span>
                    <span class="info-value"><%= email %></span>
                </div>
                <div class="info-row">
                    <span class="info-label"><i class="fas fa-phone"></i> &nbsp; Phone</span>
                    <span class="info-value"><%= phone %></span>
                </div>
                <div class="info-row">
                    <span class="info-label"><i class="fas fa-map-marker-alt"></i> &nbsp; Address</span>
                    <span class="info-value"><%= address %></span>
                </div>
                <div class="info-row">
                    <span class="info-label"><i class="fas fa-user-tag"></i> &nbsp; Account Role</span>
                    <span class="badge badge-paid">Resident User</span>
                </div>
            </div>
        </div>
    </div>

    <!-- TIPS TAB -->
    <div id="tips" class="tab-content">
        <div style="display:grid; grid-template-columns:1fr 1fr; gap:22px;">
            <div class="card" style="border-top:6px solid var(--success);">
                <h3 style="color:var(--success); margin-top:0;"><i class="fas fa-check-circle"></i> System Status</h3>
                <p>No Leakage Detected. Your inlet and outlet flow rates are balanced. Your water quality reading is normal.</p>
                <div style="display:flex; gap:10px; margin-top:12px;">
                    <div style="flex:1; background:#f0fdf4; padding:12px; border-radius:12px; text-align:center;">
                        <div style="font-weight:800; color:var(--success);">Normal</div>
                        <div style="font-size:0.75rem; color:#64748b;">Pressure</div>
                    </div>
                    <div style="flex:1; background:#f0fdf4; padding:12px; border-radius:12px; text-align:center;">
                        <div style="font-weight:800; color:var(--success);">Good</div>
                        <div style="font-size:0.75rem; color:#64748b;">Water Quality</div>
                    </div>
                    <div style="flex:1; background:#f0fdf4; padding:12px; border-radius:12px; text-align:center;">
                        <div style="font-weight:800; color:var(--success);">0</div>
                        <div style="font-size:0.75rem; color:#64748b;">Leaks</div>
                    </div>
                </div>
            </div>

            <div class="card" style="border-top:6px solid var(--primary);">
                <h3 style="color:var(--primary); margin-top:0;"><i class="fas fa-lightbulb"></i> Save Water Tips</h3>
                <ul style="line-height:2; color:#475569; padding-left:18px;">
                    <li>Fix leaking taps immediately — a dripping tap wastes 15+ litres/day</li>
                    <li>Take shorter showers (5 min = ~50 litres saved)</li>
                    <li>Collect RO reject water for mopping or plants</li>
                    <li>Wash full loads of laundry only</li>
                    <li>Turn off tap while brushing teeth</li>
                </ul>
            </div>

            <div class="card" style="border-top:6px solid var(--warning); grid-column:span 2;">
                <h3 style="color:var(--warning); margin-top:0;"><i class="fas fa-exclamation-triangle"></i> Important Notices</h3>
                <div style="display:grid; grid-template-columns:repeat(3,1fr); gap:14px;">
                    <div style="background:#fffbeb; padding:16px; border-radius:14px;">
                        <div style="font-weight:700; margin-bottom:4px;">Scheduled Maintenance</div>
                        <div style="font-size:0.82rem; color:#64748b;">Mar 20, 8AM–12PM. Store water in advance.</div>
                    </div>
                    <div style="background:#fffbeb; padding:16px; border-radius:14px;">
                        <div style="font-weight:700; margin-bottom:4px;">Rate Update</div>
                        <div style="font-size:0.82rem; color:#64748b;">Current rate: Rs. 2/litre. No changes scheduled.</div>
                    </div>
                    <div style="background:#fffbeb; padding:16px; border-radius:14px;">
                        <div style="font-weight:700; margin-bottom:4px;">Helpline</div>
                        <div style="font-size:0.82rem; color:#64748b;">Call 1800-XXX-WATER for complaints and support.</div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    function openTab(id, el) {
        document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
        document.getElementById(id).classList.add('active');
        el.classList.add('active');
    }

    function payNow(amt) {
        alert('Proceeding to payment of Rs. ' + amt + '\n\nUPI: water@payments\n\n(Payment gateway integration coming soon)');
    }

    // Usage goal bar
    const usage = <%= myTotalUsage %>;
    const goal = 1000;
    const pct = Math.min((usage / goal) * 100, 100).toFixed(1);
    document.getElementById('usageGoalBar').style.width = pct + '%';
    const gt = document.getElementById('goalText');
    if(usage >= goal) {
        gt.textContent = '⚠️ Goal exceeded! ' + pct + '% used. Please conserve water.';
        gt.style.color = '#f43f5e';
    } else {
        gt.textContent = pct + '% of monthly goal used — you\'re on track!';
    }

    // Charts
    const ctx1 = document.getElementById('myUsageChart').getContext('2d');
    new Chart(ctx1, {
        type: 'line',
        data: {
            labels: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
            datasets: [{
                label: 'Litres', data: [80,95,60,110,70,130,90],
                borderColor: '#0ea5e9', backgroundColor: 'rgba(14,165,233,0.08)',
                tension: 0.4, fill: true, pointBackgroundColor: '#0ea5e9'
            }]
        },
        options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } }
    });

    const ctx2 = document.getElementById('weekChart').getContext('2d');
    new Chart(ctx2, {
        type: 'bar',
        data: {
            labels: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'],
            datasets: [{ label: 'Litres', data: [80,95,60,110,70,130,90], backgroundColor: '#0ea5e9', borderRadius: 8 }]
        },
        options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } }
    });

    const ctx3 = document.getElementById('monthChart').getContext('2d');
    new Chart(ctx3, {
        type: 'doughnut',
        data: {
            labels: ['Kitchen','Bathroom','Garden','Other'],
            datasets: [{ data: [35,40,15,10], backgroundColor: ['#0ea5e9','#6366f1','#10b981','#f59e0b'], borderWidth: 0 }]
        },
        options: { cutout: '65%' }
    });
</script>
</body>
</html>
