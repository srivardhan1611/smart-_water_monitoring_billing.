<%@ page import="java.sql.*, java.util.Date, java.text.SimpleDateFormat, com.water.DBConnection" %>
<%
    // Admin-only guard
    HttpSession adminSession = request.getSession(false);
    if(adminSession == null || !"ADMIN".equals(adminSession.getAttribute("role"))) {
        response.sendRedirect("login.html");
        return;
    }
%>
    <%
    int totalBills = 0, totalUsage = 0, totalRevenue = 0, totalUsers = 0, pendingBills = 0;
    String logTime = new SimpleDateFormat("hh:mm:ss a").format(new Date());
    String logDate = new SimpleDateFormat("dd MMM yyyy").format(new Date());

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection("jdbc:mysql://localhost:3306/water_system?useSSL=false&serverTimezone=UTC", "root", "manager");

        ResultSet rsSum = con.createStatement().executeQuery("SELECT COUNT(*), SUM(units), SUM(bill_amount) FROM usage_records");
        if(rsSum.next()) {
            totalBills   = rsSum.getInt(1);
            totalUsage   = rsSum.getInt(2);
            totalRevenue = rsSum.getInt(3);
        }

        ResultSet rsU = con.createStatement().executeQuery("SELECT COUNT(*) FROM users WHERE is_active=1");
        if(rsU.next()) totalUsers = rsU.getInt(1);

        ResultSet rsP = con.createStatement().executeQuery("SELECT COUNT(*) FROM usage_records WHERE is_paid=0");
        if(rsP.next()) pendingBills = rsP.getInt(1);

        con.close();
    } catch(Exception e) { }
%>
        <!DOCTYPE html>
        <html lang="en">

        <head>
            <meta charset="UTF-8">
            <title>Smart Water | Admin Portal</title>
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
            <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;600;700;800&display=swap" rel="stylesheet">
            <style>
                 :root {
                    --primary: #0ea5e9;
                    --sidebar-grad: linear-gradient(180deg, #0f172a 0%, #1e293b 100%);
                    --bg: #f1f5f9;
                    --card-bg: #ffffff;
                    --text: #1e293b;
                    --border: rgba(255, 255, 255, 0.7);
                    --danger: #f43f5e;
                    --success: #10b981;
                    --warning: #f59e0b;
                }
                
                body.theme-dark {
                    --bg: #0f172a;
                    --card-bg: #1e293b;
                    --text: #f1f5f9;
                    --border: #334155;
                }
                
                body.theme-emerald {
                    --primary: #10b981;
                    --bg: #f0fdf4;
                }
                
                body.theme-midnight {
                    --primary: #6366f1;
                    --bg: #eef2ff;
                }
                
                body.theme-sunset {
                    --primary: #f59e0b;
                    --bg: #fffbeb;
                }
                
                body.theme-rose {
                    --primary: #e11d48;
                    --bg: #fff1f2;
                }
                
                body.theme-slate {
                    --primary: #475569;
                    --bg: #f8fafc;
                }
                
                body {
                    margin: 0;
                    font-family: 'Plus Jakarta Sans', sans-serif;
                    background: var(--bg);
                    display: flex;
                    color: var(--text);
                    transition: all 0.3s ease;
                }
                
                .sidebar {
                    width: 260px;
                    height: 100vh;
                    background: var(--sidebar-grad);
                    color: white;
                    position: fixed;
                    display: flex;
                    flex-direction: column;
                    justify-content: space-between;
                    z-index: 1000;
                }
                
                .sidebar h2 {
                    padding: 30px;
                    text-align: center;
                    font-weight: 800;
                    background: linear-gradient(to right, #38bdf8, #818cf8);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                }
                
                .nav-item {
                    display: flex;
                    align-items: center;
                    gap: 12px;
                    color: #94a3b8;
                    padding: 15px 25px;
                    text-decoration: none;
                    cursor: pointer;
                    transition: 0.3s;
                    margin: 0 15px 5px 15px;
                    border-radius: 12px;
                    font-weight: 600;
                }
                
                .nav-item:hover,
                .nav-item.active {
                    background: rgba(255, 255, 255, 0.1);
                    color: white;
                }
                
                .nav-item.active {
                    background: var(--primary);
                    box-shadow: 0 10px 15px -3px rgba(14, 165, 233, 0.3);
                }
                
                .main {
                    margin-left: 260px;
                    padding: 40px;
                    width: calc(100% - 260px);
                }
                
                .tab-content {
                    display: none;
                    animation: fadeIn 0.4s ease;
                }
                
                .tab-content.active {
                    display: block;
                }
                
                @keyframes fadeIn {
                    from {
                        opacity: 0;
                        transform: translateY(10px);
                    }
                    to {
                        opacity: 1;
                        transform: translateY(0);
                    }
                }
                
                .card {
                    background: var(--card-bg);
                    padding: 25px;
                    border-radius: 24px;
                    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
                    margin-bottom: 25px;
                    border: 1px solid var(--border);
                }
                
                .tank-bg {
                    width: 100%;
                    height: 110px;
                    border: 3px solid #cbd5e1;
                    border-radius: 12px;
                    position: relative;
                    overflow: hidden;
                    display: flex;
                    align-items: flex-end;
                }
                
                .water-level {
                    width: 100%;
                    height: 65%;
                    background: var(--primary);
                    animation: wave 2s ease-in-out infinite alternate;
                }
                
                @keyframes wave {
                    from {
                        opacity: 0.7;
                        height: 63%;
                    }
                    to {
                        opacity: 1;
                        height: 67%;
                    }
                }
                
                table {
                    width: 100%;
                    border-collapse: collapse;
                }
                
                th {
                    background: rgba(0, 0, 0, 0.02);
                    padding: 12px;
                    text-align: left;
                    color: #64748b;
                    font-size: 0.75rem;
                    text-transform: uppercase;
                }
                
                td {
                    padding: 15px;
                    border-bottom: 1px solid rgba(0, 0, 0, 0.05);
                }
                
                input {
                    width: 100%;
                    padding: 12px;
                    border: 2px solid #f1f5f9;
                    border-radius: 12px;
                    margin-bottom: 20px;
                    outline: none;
                    font-family: inherit;
                    background: transparent;
                    color: inherit;
                }
                
                .theme-grid {
                    display: grid;
                    grid-template-columns: repeat(3, 1fr);
                    gap: 20px;
                }
                
                .theme-card {
                    padding: 20px;
                    border-radius: 15px;
                    cursor: pointer;
                    text-align: center;
                    font-weight: bold;
                    border: 2px solid transparent;
                    transition: 0.3s;
                }
                
                .theme-card:hover {
                    transform: scale(1.05);
                }
                
                .btn-pay {
                    background: var(--primary);
                    color: white;
                    border: none;
                    padding: 8px 16px;
                    border-radius: 8px;
                    font-weight: 800;
                    cursor: pointer;
                    transition: 0.2s;
                }
                
                .btn-pay:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 4px 12px rgba(14, 165, 233, 0.4);
                }
                
                .badge {
                    padding: 5px 10px;
                    border-radius: 8px;
                    font-size: 0.7rem;
                    font-weight: 700;
                }
                
                .badge-safe {
                    background: #dcfce7;
                    color: #166534;
                }
                
                .log-row {
                    padding: 12px;
                    border-bottom: 1px solid rgba(0, 0, 0, 0.05);
                    display: flex;
                    gap: 15px;
                    align-items: center;
                }

                /* ── RESIDENTS TAB ── */
                .res-table { width:100%; border-collapse:collapse; }
                .res-table th {
                    padding: 13px 16px;
                    text-align: left;
                    font-size: 0.72rem;
                    font-weight: 700;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    color: #64748b;
                    background: #f8fafc;
                    border-bottom: 2px solid #e2e8f0;
                }
                .res-table td {
                    padding: 15px 16px;
                    border-bottom: 1px solid #f1f5f9;
                    font-size: 0.88rem;
                    vertical-align: middle;
                }
                .res-table tr:last-child td { border-bottom: none; }
                .res-table tr:hover td { background: #f8fafc; }
                .user-cell { display:flex; align-items:center; gap:12px; }
                .user-ava {
                    width: 38px; height: 38px; border-radius: 50%;
                    display: flex; align-items: center; justify-content: center;
                    font-weight: 800; font-size: 13px; color: white; flex-shrink: 0;
                    background: linear-gradient(135deg, #0ea5e9, #6366f1);
                }
                .user-ava.c1 { background: linear-gradient(135deg,#0ea5e9,#06b6d4); }
                .user-ava.c2 { background: linear-gradient(135deg,#8b5cf6,#ec4899); }
                .user-ava.c3 { background: linear-gradient(135deg,#10b981,#059669); }
                .user-ava.c4 { background: linear-gradient(135deg,#f59e0b,#ef4444); }
                .user-ava.c5 { background: linear-gradient(135deg,#6366f1,#8b5cf6); }
                .user-detail .uname { font-weight: 700; font-size: 0.9rem; }
                .user-detail .umeta { font-size: 0.75rem; color: #94a3b8; margin-top: 2px; }
                .badge-paid    { display:inline-block;padding:4px 12px;border-radius:20px;font-size:0.7rem;font-weight:700;background:#dcfce7;color:#166534; }
                .badge-pending { display:inline-block;padding:4px 12px;border-radius:20px;font-size:0.7rem;font-weight:700;background:#fef9c3;color:#854d0e; }
                .badge-active  { display:inline-block;padding:4px 12px;border-radius:20px;font-size:0.7rem;font-weight:700;background:#dbeafe;color:#1e40af; }
                .usage-bar-wrap { display:flex; align-items:center; gap:10px; }
                .usage-bar-track { flex:1; height:6px; background:#e2e8f0; border-radius:6px; overflow:hidden; max-width:100px; }
                .usage-bar-fill  { height:100%; border-radius:6px; background:linear-gradient(90deg,#0ea5e9,#06b6d4); }
                .usage-bar-fill.high { background:linear-gradient(90deg,#f59e0b,#ef4444); }
                .res-summary {
                    display: grid; grid-template-columns: repeat(4,1fr);
                    gap: 16px; margin-bottom: 24px;
                }
                .res-sum-card {
                    background: var(--card-bg);
                    border-radius: 16px; padding: 18px 20px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.05);
                }
                .res-sum-card .rsc-label { font-size:0.72rem; color:#64748b; font-weight:700; text-transform:uppercase; letter-spacing:0.5px; margin-bottom:6px; }
                .res-sum-card .rsc-value { font-size:1.6rem; font-weight:800; }
                .res-toolbar {
                    display:flex; justify-content:space-between; align-items:center;
                    margin-bottom: 18px; flex-wrap: wrap; gap: 12px;
                }
                .res-search {
                    padding: 10px 14px; border: 1.5px solid #e2e8f0;
                    border-radius: 12px; font-family: inherit; font-size: 0.88rem;
                    width: 260px; outline: none; background: white; color: #1e293b;
                    transition: border-color 0.3s;
                }
                .res-search:focus { border-color: #0ea5e9; }
                .res-filter-btns { display:flex; gap:8px; }
                .filter-btn {
                    padding: 8px 16px; border-radius: 10px;
                    font-family: inherit; font-size: 0.78rem; font-weight: 700;
                    border: 1.5px solid #e2e8f0; background: white; cursor: pointer;
                    transition: all 0.2s; color: #64748b;
                }
                .filter-btn.on { background: var(--primary); color: white; border-color: var(--primary); }
                .mark-paid-btn {
                    padding: 7px 14px; background: #dcfce7;
                    border: 1px solid #bbf7d0; border-radius: 8px;
                    color: #166534; font-family: inherit; font-size: 0.78rem;
                    font-weight: 700; cursor: pointer; transition: all 0.2s;
                }
                .mark-paid-btn:hover { background: #10b981; color: white; border-color: #10b981; }
                .mark-paid-btn.done { background: #f1f5f9; color: #94a3b8; border-color: #e2e8f0; cursor: default; }

                @media print {
                    .sidebar, .no-print { display: none !important; }
                    .main { margin-left: 0; width: 100%; }
                }
            </style>
        </head>

        <body>

            <div class="sidebar">
                <div>
                    <h2>SMART WATER SYSTEM</h2>
                    <div class="nav-menu">
                        <a class="nav-item active" onclick="openTab('dash', this)"><i class="fas fa-th-large"></i> Dashboard</a>
                        <a class="nav-item" onclick="openTab('residents-tab', this)"><i class="fas fa-users"></i> Residents</a>
                        <a class="nav-item" onclick="openTab('billing', this)"><i class="fas fa-plus-circle"></i> Create Bill</a>
                        <a class="nav-item" onclick="openTab('history', this)"><i class="fas fa-history"></i> History</a>
                        <a class="nav-item" onclick="openTab('tips-tab', this)"><i class="fas fa-lightbulb"></i> Tips & Leakage</a>
                        <a class="nav-item" onclick="openTab('logs-tab', this)"><i class="fas fa-clipboard-list"></i> Activity Logs</a>
                        <a class="nav-item" onclick="openTab('themes-tab', this)"><i class="fas fa-palette"></i> Themes</a>
                        <a class="nav-item" href="iot_coming_soon.html" style="color:#f59e0b;"><i class="fas fa-microchip"></i> IoT Features <span style="font-size:0.6rem;background:rgba(245,158,11,0.2);padding:2px 6px;border-radius:10px;margin-left:4px;font-weight:800;">SOON</span></a>
                    </div>
                </div>
                <a href="logout" class="nav-item"><i class="fas fa-power-off"></i> Logout</a>
            </div>

            <div class="main">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom: 30px;">
                    <div>
                        <h1 style="font-weight: 800; margin:0;">Welcome Admin!</h1>
                        <p style="margin:5px 0 0 0; color:#64748b;">Grid Status: <span style="color:var(--success); font-weight:bold;">Online</span> | Rate: Rs. 2/Litre</p>
                    </div>
                    <div style="text-align: right;">
                        <div style="font-weight: 700; color: var(--primary);">
                            <%= logTime %>
                        </div>
                        <div style="color: #64748b; font-size: 0.85rem;">
                            <%= logDate %>
                        </div>
                    </div>
                </div>

                <div id="dash" class="tab-content active">
                    <div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 25px;">
                        <div class="card" style="border-top:4px solid var(--primary);">
                            <div style="font-size:0.72rem;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;">Bills Issued</div>
                            <div style="font-size:1.9rem;font-weight:800;color:var(--primary);"><%=totalBills%></div>
                        </div>
                        <div class="card" style="border-top:4px solid #8b5cf6;">
                            <div style="font-size:0.72rem;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;">Total Usage</div>
                            <div style="font-size:1.9rem;font-weight:800;color:#8b5cf6;"><%=totalUsage%> L</div>
                        </div>
                        <div class="card" style="border-top:4px solid var(--success);">
                            <div style="font-size:0.72rem;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;">Total Revenue</div>
                            <div style="font-size:1.9rem;font-weight:800;color:var(--success);">Rs. <%=totalRevenue%></div>
                        </div>
                        <div class="card" style="border-top:4px solid var(--warning);">
                            <div style="font-size:0.72rem;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;">Pending Bills</div>
                            <div style="font-size:1.9rem;font-weight:800;color:var(--warning);"><%=pendingBills%></div>
                            <div style="font-size:0.75rem;color:#94a3b8;margin-top:4px;">
                                <a onclick="openTab('residents-tab', document.querySelector('[onclick*=residents-tab]'))"
                                   style="color:var(--warning);font-weight:700;cursor:pointer;">View unpaid &rarr;</a>
                            </div>
                        </div>
                    </div>

                    <div style="display: grid; grid-template-columns: 1.5fr 1fr; gap: 25px; margin-bottom:25px;">
                        <div>
                            <div class="card">
                                <h3>7-Day Consumption Trend</h3>
                                <canvas id="usageChart" height="120"></canvas>
                            </div>
                            <!-- ── RESIDENTS BILLING OVERVIEW ── -->
                            <div class="card" style="padding:0;overflow:hidden;">
                                <div style="padding:20px 24px 16px;display:flex;justify-content:space-between;align-items:center;border-bottom:1px solid #f1f5f9;">
                                    <div>
                                        <h3 style="margin:0;font-size:1rem;font-weight:800;">Residents — Usage & Bills</h3>
                                        <p style="margin:3px 0 0;font-size:0.78rem;color:#64748b;">All registered users · sorted by pending amount</p>
                                    </div>
                                    <a onclick="openTab('residents-tab', document.querySelector('[onclick*=residents-tab]'))"
                                       style="font-size:0.78rem;color:var(--primary);font-weight:700;cursor:pointer;text-decoration:none;white-space:nowrap;">
                                        Full Details &rarr;
                                    </a>
                                </div>

                                <!-- mini search -->
                                <div style="padding:12px 24px;border-bottom:1px solid #f1f5f9;background:#fafbfc;">
                                    <input id="dashResSearch" onkeyup="filterDashRes()" placeholder="&#xf002;  Quick search resident..."
                                        style="width:100%;padding:9px 13px;border:1.5px solid #e2e8f0;border-radius:10px;font-family:inherit;font-size:0.85rem;outline:none;background:white;color:#1e293b;">
                                </div>

                                <div style="overflow-x:auto;">
                                <table style="width:100%;border-collapse:collapse;" id="dashResTable">
                                    <thead>
                                        <tr style="background:#f8fafc;">
                                            <th style="padding:11px 16px;text-align:left;font-size:0.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:#64748b;border-bottom:2px solid #e2e8f0;">Resident</th>
                                            <th style="padding:11px 16px;text-align:left;font-size:0.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:#64748b;border-bottom:2px solid #e2e8f0;">Meter No.</th>
                                            <th style="padding:11px 16px;text-align:left;font-size:0.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:#64748b;border-bottom:2px solid #e2e8f0;">Total Usage</th>
                                            <th style="padding:11px 16px;text-align:left;font-size:0.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:#64748b;border-bottom:2px solid #e2e8f0;">Total Billed</th>
                                            <th style="padding:11px 16px;text-align:left;font-size:0.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:#64748b;border-bottom:2px solid #e2e8f0;">Pending</th>
                                            <th style="padding:11px 16px;text-align:left;font-size:0.7rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:#64748b;border-bottom:2px solid #e2e8f0;">Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                    <%
                                        String[] dashColors = {"#0ea5e9","#8b5cf6","#10b981","#f59e0b","#f43f5e"};
                                        String[] dashGrads  = {
                                            "linear-gradient(135deg,#0ea5e9,#06b6d4)",
                                            "linear-gradient(135deg,#8b5cf6,#ec4899)",
                                            "linear-gradient(135deg,#10b981,#059669)",
                                            "linear-gradient(135deg,#f59e0b,#ef4444)",
                                            "linear-gradient(135deg,#6366f1,#8b5cf6)"
                                        };
                                        int dri = 0;
                                        boolean anyDash = false;
                                        try {
                                            Connection conD = DBConnection.getConnection();
                                            ResultSet rsD = conD.createStatement().executeQuery(
                                                "SELECT u.first_name, u.last_name, u.username, u.meter_no, u.phone, " +
                                                "COALESCE(SUM(ur.units),0) AS total_units, " +
                                                "COALESCE(SUM(ur.bill_amount),0) AS total_billed, " +
                                                "COALESCE(SUM(CASE WHEN ur.is_paid=0 THEN ur.bill_amount ELSE 0 END),0) AS pending_amt, " +
                                                "COUNT(ur.id) AS bill_count " +
                                                "FROM users u LEFT JOIN usage_records ur ON ur.customer_name=u.username " +
                                                "WHERE u.role='USER' AND u.is_active=1 " +
                                                "GROUP BY u.id ORDER BY pending_amt DESC, total_units DESC");
                                            while(rsD.next()) {
                                                anyDash = true;
                                                String dfn   = rsD.getString("first_name");
                                                String dln   = rsD.getString("last_name");
                                                String duser = rsD.getString("username");
                                                String dmtr  = rsD.getString("meter_no");
                                                int    dunit = rsD.getInt("total_units");
                                                long   dbill = rsD.getLong("total_billed");
                                                long   dpend = rsD.getLong("pending_amt");
                                                int    dcnt  = rsD.getInt("bill_count");
                                                String dinit = (dfn.length()>0?String.valueOf(dfn.charAt(0)):"")
                                                             + (dln.length()>0?String.valueOf(dln.charAt(0)):"");
                                                String dgrad = dashGrads[dri % dashGrads.length];
                                                String dcol  = dashColors[dri % dashColors.length];
                                                int barW = Math.min((int)((dunit/1000.0)*100),100);
                                                boolean dhigh = dunit > 800;
                                                dri++;
                                    %>
                                        <tr class="dash-res-row" style="transition:background .15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='white'">
                                            <!-- Name -->
                                            <td style="padding:14px 16px;">
                                                <div style="display:flex;align-items:center;gap:11px;">
                                                    <div style="width:36px;height:36px;border-radius:50%;background:<%=dgrad%>;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:12px;color:white;flex-shrink:0;"><%=dinit.toUpperCase()%></div>
                                                    <div>
                                                        <div style="font-weight:700;font-size:0.88rem;"><%=dfn%> <%=dln%></div>
                                                        <div style="font-size:0.72rem;color:#94a3b8;margin-top:1px;">@<%=duser%> &nbsp;·&nbsp; <%=dcnt%> bill(s)</div>
                                                    </div>
                                                </div>
                                            </td>
                                            <!-- Meter -->
                                            <td style="padding:14px 16px;font-family:monospace;font-size:0.8rem;color:#0ea5e9;font-weight:600;"><%=dmtr%></td>
                                            <!-- Usage with bar -->
                                            <td style="padding:14px 16px;">
                                                <div style="display:flex;align-items:center;gap:9px;">
                                                    <span style="font-weight:700;min-width:48px;font-size:0.88rem;"><%=dunit%> L</span>
                                                    <div style="flex:1;height:5px;background:#e2e8f0;border-radius:5px;overflow:hidden;max-width:80px;">
                                                        <div style="height:100%;width:<%=barW%>%;border-radius:5px;background:<%=dhigh?"linear-gradient(90deg,#f59e0b,#ef4444)":"linear-gradient(90deg,#0ea5e9,#06b6d4)"%>;"></div>
                                                    </div>
                                                </div>
                                            </td>
                                            <!-- Billed -->
                                            <td style="padding:14px 16px;font-weight:700;font-size:0.88rem;">Rs. <%=dbill%></td>
                                            <!-- Pending -->
                                            <td style="padding:14px 16px;">
                                                <% if(dpend > 0) { %>
                                                    <span style="font-weight:800;color:#f43f5e;font-size:0.9rem;">Rs. <%=dpend%></span>
                                                <% } else { %>
                                                    <span style="color:#10b981;font-weight:700;font-size:0.88rem;">&#10003; Nil</span>
                                                <% } %>
                                            </td>
                                            <!-- Status badge -->
                                            <td style="padding:14px 16px;">
                                                <% if(dpend > 0) { %>
                                                    <span style="display:inline-block;padding:4px 11px;border-radius:20px;font-size:0.68rem;font-weight:700;background:#fef9c3;color:#854d0e;">Pending</span>
                                                <% } else { %>
                                                    <span style="display:inline-block;padding:4px 11px;border-radius:20px;font-size:0.68rem;font-weight:700;background:#dcfce7;color:#166534;">Paid</span>
                                                <% } %>
                                            </td>
                                        </tr>
                                    <%
                                            }
                                            conD.close();
                                        } catch(Exception de) {}
                                        if(!anyDash) {
                                    %>
                                        <tr>
                                            <td colspan="6" style="padding:40px;text-align:center;color:#94a3b8;">
                                                <i class="fas fa-users" style="font-size:2rem;display:block;margin-bottom:10px;opacity:.4;"></i>
                                                No residents registered yet.
                                            </td>
                                        </tr>
                                    <% } %>
                                    </tbody>
                                </table>
                                </div>
                            </div>
                        </div>

                        <div>
                            <div class="card" onclick="window.location.href='iot_coming_soon.html'" style="cursor:pointer; position:relative;">
                                <div style="position:absolute;top:14px;right:14px;background:rgba(245,158,11,0.15);color:#f59e0b;font-size:0.65rem;font-weight:800;padding:3px 9px;border-radius:20px;border:1px solid rgba(245,158,11,0.3);text-transform:uppercase;letter-spacing:0.8px;">IoT Pending</div>
                                <h3>Reservoir Tank</h3>
                                <div class="tank-bg">
                                    <div class="water-level"></div>
                                </div>
                                <p style="text-align:center; font-weight:700; margin-top:15px; color:#64748b; font-size:0.85rem;"><i class="fas fa-microchip" style="margin-right:6px;color:#f59e0b;"></i>Live data available after sensor install</p>
                            </div>
                            <div class="card" style="background: linear-gradient(135deg, #38bdf8 0%, #0ea5e9 100%); color:white;">
                                <h3>Local Weather</h3>
                                <div style="display:flex; align-items:center; gap:20px;">
                                    <i class="fas fa-sun fa-3x" style="color:#fbbf24;"></i>
                                    <div>
                                        <div style="font-size:2rem; font-weight:800;">32 deg C</div>
                                        <div style="font-weight:600;">Hyderabad: Sunny</div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div id="themes-tab" class="tab-content">
                    <div class="card">
                        <h2 style="margin-top:0;">Select Portal Theme</h2>
                        <div class="theme-grid">
                            <div class="theme-card" style="background:#f1f5f9; color:#1e293b;" onclick="setTheme('default')">Default Sky</div>
                            <div class="theme-card" style="background:#0f172a; color:#fff;" onclick="setTheme('theme-dark')">Deep Dark</div>
                            <div class="theme-card" style="background:#10b981; color:#fff;" onclick="setTheme('theme-emerald')">Emerald Forest</div>
                            <div class="theme-card" style="background:#6366f1; color:#fff;" onclick="setTheme('theme-midnight')">Midnight Indigo</div>
                            <div class="theme-card" style="background:#f59e0b; color:#fff;" onclick="setTheme('theme-sunset')">Sunset Amber</div>
                            <div class="theme-card" style="background:#e11d48; color:#fff;" onclick="setTheme('theme-rose')">Elegant Rose</div>
                        </div>
                    </div>
                </div>

                <div id="billing" class="tab-content">
                    <%
                        /* Load all registered users for the dropdown */
                        java.util.List<String[]> residentList = new java.util.ArrayList<>();
                        try {
                            Connection conBL = DBConnection.getConnection();
                            if(conBL != null) {
                                ResultSet rsBL = conBL.createStatement().executeQuery(
                                    "SELECT id, first_name, last_name, username, phone, meter_no, address " +
                                    "FROM users WHERE role='USER' AND is_active=1 ORDER BY first_name ASC");
                                while(rsBL.next()) {
                                    residentList.add(new String[]{
                                        rsBL.getString("id"),
                                        rsBL.getString("first_name") + " " + rsBL.getString("last_name"),
                                        rsBL.getString("username"),
                                        rsBL.getString("phone"),
                                        rsBL.getString("meter_no"),
                                        rsBL.getString("address")
                                    });
                                }
                                conBL.close();
                            }
                        } catch(Exception blEx) {}
                    %>

                    <!-- Success / error flash -->
                    <%
                        String billMsg = request.getParameter("bill");
                        String billErr = request.getParameter("err");
                    %>
                    <% if("saved".equals(billMsg)) { %>
                    <div style="background:#f0fdf4;border:1.5px solid #10b981;border-radius:14px;padding:14px 20px;margin-bottom:20px;display:flex;align-items:center;gap:12px;">
                        <i class="fas fa-check-circle" style="color:#10b981;font-size:18px;"></i>
                        <span style="font-weight:700;color:#065f46;">Bill generated and saved successfully!</span>
                    </div>
                    <% } %>
                    <% if(billErr != null) { %>
                    <div style="background:#fff1f2;border:1.5px solid #f43f5e;border-radius:14px;padding:14px 20px;margin-bottom:20px;display:flex;align-items:center;gap:12px;">
                        <i class="fas fa-exclamation-circle" style="color:#f43f5e;font-size:18px;"></i>
                        <span style="font-weight:700;color:#9f1239;">Error saving bill: <%=billErr%></span>
                    </div>
                    <% } %>

                    <div style="display:grid;grid-template-columns:1fr 1fr;gap:24px;align-items:start;">

                        <!-- LEFT: Bill Form -->
                        <div class="card" style="padding:32px;">
                            <h3 style="margin:0 0 6px;font-weight:800;font-size:1.1rem;">
                                <i class="fas fa-file-invoice" style="color:var(--primary);margin-right:8px;"></i>Generate Bill
                            </h3>
                            <p style="color:#64748b;font-size:0.85rem;margin:0 0 24px;">Select a resident and enter their water usage to generate a bill.</p>

                            <form action="save_bill.jsp" method="POST" onsubmit="return confirmBill()">

                                <!-- Resident Dropdown -->
                                <div style="margin-bottom:18px;">
                                    <label style="display:block;font-size:0.75rem;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;">
                                        Select Resident <span style="color:#f43f5e;">*</span>
                                    </label>
                                    <select name="customer_name" id="residentSelect" onchange="fillResident(this)"
                                        style="width:100%;padding:12px 14px;border:1.5px solid #e2e8f0;border-radius:12px;font-family:inherit;font-size:0.9rem;outline:none;background:white;color:#1e293b;cursor:pointer;"
                                        required>
                                        <option value="">-- Choose a resident --</option>
                                        <% for(String[] r : residentList) { %>
                                        <option value="<%=r[2]%>"
                                            data-name="<%=r[1]%>"
                                            data-phone="<%=r[3]%>"
                                            data-meter="<%=r[4]%>"
                                            data-addr="<%=r[5]%>">
                                            <%=r[1]%> &nbsp;·&nbsp; @<%=r[2]%> &nbsp;·&nbsp; <%=r[4]%>
                                        </option>
                                        <% } %>
                                        <% if(residentList.isEmpty()) { %>
                                        <option disabled>No residents registered yet</option>
                                        <% } %>
                                    </select>
                                </div>

                                <!-- Resident info strip (fills on select) -->
                                <div id="resInfo" style="display:none;background:#f8fafc;border:1px solid #e2e8f0;border-radius:12px;padding:14px 16px;margin-bottom:18px;">
                                    <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;font-size:0.82rem;">
                                        <div><span style="color:#94a3b8;font-weight:600;">Name:</span> <strong id="ri-name"></strong></div>
                                        <div><span style="color:#94a3b8;font-weight:600;">Phone:</span> <span id="ri-phone"></span></div>
                                        <div><span style="color:#94a3b8;font-weight:600;">Meter:</span> <span id="ri-meter" style="font-family:monospace;color:#0ea5e9;font-weight:600;"></span></div>
                                        <div><span style="color:#94a3b8;font-weight:600;">Address:</span> <span id="ri-addr"></span></div>
                                    </div>
                                </div>

                                <!-- Usage Input -->
                                <div style="margin-bottom:18px;">
                                    <label style="display:block;font-size:0.75rem;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;">
                                        Water Usage (Litres) <span style="color:#f43f5e;">*</span>
                                    </label>
                                    <input type="number" id="unitInput" name="units" min="1" max="99999"
                                        placeholder="Enter usage in litres e.g. 450"
                                        oninput="calcBill()"
                                        style="width:100%;padding:12px 14px;border:1.5px solid #e2e8f0;border-radius:12px;font-family:inherit;font-size:0.9rem;outline:none;color:#1e293b;background:white;transition:border-color .2s;"
                                        required>
                                </div>

                                <!-- Bill Preview Box -->
                                <div style="background:linear-gradient(135deg,rgba(14,165,233,0.08),rgba(6,182,212,0.05));border:2px dashed var(--primary);border-radius:16px;padding:22px;text-align:center;margin-bottom:20px;">
                                    <div style="font-size:0.7rem;font-weight:800;text-transform:uppercase;letter-spacing:1.5px;color:#0ea5e9;margin-bottom:6px;">Bill Amount @ Rs. 2 / Litre</div>
                                    <div style="font-size:2.6rem;font-weight:900;color:#0f172a;letter-spacing:-1px;">
                                        Rs. <span id="dispAmt">0.00</span>
                                    </div>
                                    <div style="font-size:0.78rem;color:#94a3b8;margin-top:6px;" id="billBreakdown">Enter usage above to calculate</div>
                                    <input type="hidden" name="bill_amount" id="hidAmt" value="0">
                                </div>

                                <!-- Billing Date -->
                                <div style="margin-bottom:20px;">
                                    <label style="display:block;font-size:0.75rem;font-weight:700;color:#64748b;text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px;">
                                        Billing Date
                                    </label>
                                    <input type="date" name="bill_date" id="billDate"
                                        style="width:100%;padding:12px 14px;border:1.5px solid #e2e8f0;border-radius:12px;font-family:inherit;font-size:0.9rem;outline:none;color:#1e293b;background:white;">
                                </div>

                                <!-- Submit -->
                                <button type="submit" id="submitBillBtn"
                                    style="width:100%;padding:15px;background:linear-gradient(135deg,var(--primary),#0284c7);color:white;border:none;border-radius:14px;font-family:inherit;font-size:1rem;font-weight:800;cursor:pointer;transition:all .2s;box-shadow:0 4px 15px rgba(14,165,233,0.3);">
                                    <i class="fas fa-paper-plane" style="margin-right:8px;"></i>Generate &amp; Save Bill
                                </button>
                            </form>
                        </div>

                        <!-- RIGHT: Recent bills + quick stats -->
                        <div style="display:flex;flex-direction:column;gap:20px;">

                            <!-- Quick stats -->
                            <div style="display:grid;grid-template-columns:1fr 1fr;gap:14px;">
                                <div class="card" style="padding:18px 20px;">
                                    <div style="font-size:0.72rem;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;">Total Bills</div>
                                    <div style="font-size:1.8rem;font-weight:800;color:var(--primary);"><%=totalBills%></div>
                                </div>
                                <div class="card" style="padding:18px 20px;">
                                    <div style="font-size:0.72rem;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;">Total Revenue</div>
                                    <div style="font-size:1.8rem;font-weight:800;color:var(--success);">Rs.<%=totalRevenue%></div>
                                </div>
                                <div class="card" style="padding:18px 20px;">
                                    <div style="font-size:0.72rem;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;">Residents</div>
                                    <div style="font-size:1.8rem;font-weight:800;color:#8b5cf6;"><%=residentList.size()%></div>
                                </div>
                                <div class="card" style="padding:18px 20px;">
                                    <div style="font-size:0.72rem;color:#64748b;font-weight:700;text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px;">Pending Bills</div>
                                    <div style="font-size:1.8rem;font-weight:800;color:var(--warning);"><%=pendingBills%></div>
                                </div>
                            </div>

                            <!-- Last 5 bills -->
                            <div class="card" style="padding:0;overflow:hidden;">
                                <div style="padding:16px 20px;border-bottom:1px solid #f1f5f9;font-weight:800;font-size:0.92rem;">
                                    <i class="fas fa-history" style="color:var(--primary);margin-right:8px;"></i>Recent Bills
                                </div>
                                <table style="width:100%;border-collapse:collapse;">
                                    <thead>
                                        <tr style="background:#f8fafc;">
                                            <th style="padding:10px 14px;text-align:left;font-size:0.68rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:#64748b;border-bottom:1px solid #f1f5f9;">Resident</th>
                                            <th style="padding:10px 14px;text-align:left;font-size:0.68rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:#64748b;border-bottom:1px solid #f1f5f9;">Usage</th>
                                            <th style="padding:10px 14px;text-align:left;font-size:0.68rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:#64748b;border-bottom:1px solid #f1f5f9;">Amount</th>
                                            <th style="padding:10px 14px;text-align:left;font-size:0.68rem;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:#64748b;border-bottom:1px solid #f1f5f9;">Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                    <%
                                        try {
                                            Connection conRec = DBConnection.getConnection();
                                            if(conRec != null) {
                                                ResultSet rsRec = conRec.createStatement().executeQuery(
                                                    "SELECT customer_name, units, bill_amount, bill_date, is_paid FROM usage_records ORDER BY id DESC LIMIT 8");
                                                boolean anyRec = false;
                                                while(rsRec.next()) {
                                                    anyRec = true;
                                                    String recName = rsRec.getString("customer_name");
                                                    int recUnits   = rsRec.getInt("units");
                                                    int recAmt     = rsRec.getInt("bill_amount");
                                                    boolean recPaid= rsRec.getInt("is_paid") == 1;
                                                    String recDate = rsRec.getString("bill_date");
                                                    if(recDate != null && recDate.length() > 10) recDate = recDate.substring(0,10);
                                    %>
                                        <tr onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='white'" style="transition:background .15s;">
                                            <td style="padding:11px 14px;font-weight:700;font-size:0.85rem;"><%=recName%><br><span style="font-size:0.72rem;color:#94a3b8;font-weight:400;"><%=recDate != null ? recDate : ""%></span></td>
                                            <td style="padding:11px 14px;font-size:0.85rem;color:#475569;"><%=recUnits%> L</td>
                                            <td style="padding:11px 14px;font-weight:700;color:var(--success);font-size:0.88rem;">Rs.<%=recAmt%></td>
                                            <td style="padding:11px 14px;">
                                                <% if(recPaid) { %>
                                                <span style="background:#dcfce7;color:#166534;padding:3px 9px;border-radius:20px;font-size:0.65rem;font-weight:700;">Paid</span>
                                                <% } else { %>
                                                <span style="background:#fef9c3;color:#854d0e;padding:3px 9px;border-radius:20px;font-size:0.65rem;font-weight:700;">Pending</span>
                                                <% } %>
                                            </td>
                                        </tr>
                                    <%
                                                }
                                                if(!anyRec) {
                                    %>
                                        <tr><td colspan="4" style="padding:28px;text-align:center;color:#94a3b8;font-size:0.85rem;">No bills generated yet.</td></tr>
                                    <%
                                                }
                                                conRec.close();
                                            }
                                        } catch(Exception recEx) {}
                                    %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

                <div id="history" class="tab-content">
                    <div class="card">
                        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:20px;">
                            <h3>Transaction History</h3>
                            <div style="display:flex; gap:10px;">
                                <input type="text" id="histSearch" onkeyup="filterHistory()" placeholder="Search resident name..." style="width:250px; margin-bottom:0; background:white; color:#1e293b; border:1px solid #ddd;">
                                <button class="no-print" onclick="window.print()" style="padding:10px 15px; border-radius:10px; border:1px solid #ddd; cursor:pointer;"><i class="fas fa-print"></i></button>
                            </div>
                        </div>
                        <table id="historyTable">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Resident</th>
                                    <th>Usage (L)</th>
                                    <th>Bill Amount</th>
                                    <th>Payment Info</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% try {
                            Connection conH = DriverManager.getConnection("jdbc:mysql://localhost:3306/water_system", "root", "manager");
                            ResultSet rsH = conH.createStatement().executeQuery("SELECT * FROM usage_records ORDER BY id DESC");
                            while(rsH.next()){
                        %>
                                    <tr>
                                        <td>#
                                            <%=rsH.getInt("id")%>
                                        </td>
                                        <td class="cust-name"><strong><%=rsH.getString("customer_name")%></strong></td>
                                        <td>
                                            <%=rsH.getInt("units")%> Litres</td>
                                        <td style="color:var(--success); font-weight:700;">Rs.
                                            <%=rsH.getInt("bill_amount")%>
                                        </td>
                                        <td><button class="btn-pay" onclick="alert('Phone: 770xxxx404 - Proceeding to payment...')">Pay</button></td>
                                    </tr>
                                    <% } conH.close(); } catch(Exception e){ } %>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div id="tips-tab" class="tab-content">
                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
                        <div class="card" style="border-top: 8px solid var(--success);">
                            <h3 style="color:var(--success);"><i class="fas fa-check-circle"></i> Leakage Status</h3>
                            <p>No Leakage Detected. Inlet and outlet flow rates are balanced.</p>
                        </div>
                        <div class="card" style="border-top: 8px solid var(--primary);">
                            <h3 style="color:var(--primary);"><i class="fas fa-tint"></i> Conservation Tips</h3>
                            <ul>
                                <li>Check Faucets</li>
                                <li>Fix leaking taps immediately</li>
                                <li> Reuse water for gardening</li>
                            </ul>
                        </div>
                    </div>
                </div>

                <div id="residents-tab" class="tab-content">
                    <%
                        /* ── Per-user summary stats ── */
                        int totalResidents = 0, activeRes = 0, pendingPayRes = 0;
                        long totalPendingAmt = 0;
                        try {
                            Connection conRes = DBConnection.getConnection();
                            ResultSet rsCnt = conRes.createStatement().executeQuery(
                                "SELECT COUNT(*) FROM users WHERE is_active=1 AND role='USER'");
                            if(rsCnt.next()) totalResidents = rsCnt.getInt(1);

                            ResultSet rsPend = conRes.createStatement().executeQuery(
                                "SELECT COUNT(DISTINCT customer_name), SUM(bill_amount) FROM usage_records WHERE is_paid=0");
                            if(rsPend.next()) { pendingPayRes = rsPend.getInt(1); totalPendingAmt = rsPend.getLong(2); }
                            conRes.close();
                        } catch(Exception ex) {}
                    %>

                    <!-- Summary cards -->
                    <div class="res-summary">
                        <div class="res-sum-card">
                            <div class="rsc-label">Total Residents</div>
                            <div class="rsc-value" style="color:#0ea5e9;"><%=totalResidents%></div>
                        </div>
                        <div class="res-sum-card">
                            <div class="rsc-label">Total Bills Issued</div>
                            <div class="rsc-value" style="color:#8b5cf6;"><%=totalBills%></div>
                        </div>
                        <div class="res-sum-card">
                            <div class="rsc-label">Pending Payments</div>
                            <div class="rsc-value" style="color:#f59e0b;"><%=pendingBills%></div>
                        </div>
                        <div class="res-sum-card">
                            <div class="rsc-label">Pending Amount</div>
                            <div class="rsc-value" style="color:#f43f5e;">Rs.<%=totalPendingAmt%></div>
                        </div>
                    </div>

                    <!-- Toolbar -->
                    <div class="res-toolbar">
                        <input class="res-search" id="resSearch" onkeyup="filterResidents()"
                               placeholder="&#xf002;  Search by name, username or meter...">
                        <div style="display:flex;align-items:center;gap:10px;">
                            <div class="res-filter-btns">
                                <button class="filter-btn on" onclick="filterStatus('all',this)">All</button>
                                <button class="filter-btn" onclick="filterStatus('pending',this)">Pending</button>
                                <button class="filter-btn" onclick="filterStatus('paid',this)">Paid</button>
                            </div>
                            <button class="no-print" onclick="window.print()"
                                style="padding:9px 14px;border-radius:10px;border:1px solid #e2e8f0;cursor:pointer;background:white;font-size:0.82rem;">
                                <i class="fas fa-print"></i> Print
                            </button>
                        </div>
                    </div>

                    <!-- Main residents table -->
                    <div class="card" style="padding:0; overflow:hidden;">
                        <table class="res-table" id="resTable">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Resident</th>
                                    <th>Meter No.</th>
                                    <th>Phone</th>
                                    <th>Total Usage</th>
                                    <th>Total Billed</th>
                                    <th>Amount Pending</th>
                                    <th>Last Bill Date</th>
                                    <th>Status</th>
                                    <th class="no-print">Action</th>
                                </tr>
                            </thead>
                            <tbody>
                            <%
                                String[] avatarClasses = {"c1","c2","c3","c4","c5"};
                                int rowIdx = 0;
                                try {
                                    Connection conRt = DBConnection.getConnection();
                                    /* Join users with aggregated billing data */
                                    String sql = "SELECT u.id, u.first_name, u.last_name, u.username, " +
                                                 "u.phone, u.meter_no, u.address, " +
                                                 "COALESCE(SUM(ur.units),0) AS total_units, " +
                                                 "COALESCE(SUM(ur.bill_amount),0) AS total_billed, " +
                                                 "COALESCE(SUM(CASE WHEN ur.is_paid=0 THEN ur.bill_amount ELSE 0 END),0) AS pending_amt, " +
                                                 "COUNT(ur.id) AS bill_count, " +
                                                 "MAX(ur.bill_date) AS last_bill " +
                                                 "FROM users u " +
                                                 "LEFT JOIN usage_records ur ON ur.customer_name = u.username " +
                                                 "WHERE u.role='USER' AND u.is_active=1 " +
                                                 "GROUP BY u.id ORDER BY pending_amt DESC, u.first_name ASC";

                                    PreparedStatement psRt = conRt.prepareStatement(sql);
                                    ResultSet rsRt = psRt.executeQuery();

                                    while(rsRt.next()) {
                                        rowIdx++;
                                        String fname    = rsRt.getString("first_name");
                                        String lname    = rsRt.getString("last_name");
                                        String uname    = rsRt.getString("username");
                                        String phone    = rsRt.getString("phone");
                                        String meter    = rsRt.getString("meter_no");
                                        int    units    = rsRt.getInt("total_units");
                                        long   billed   = rsRt.getLong("total_billed");
                                        long   pending  = rsRt.getLong("pending_amt");
                                        int    billCnt  = rsRt.getInt("bill_count");
                                        String lastBill = rsRt.getString("last_bill");
                                        if(lastBill != null && lastBill.length() > 10) lastBill = lastBill.substring(0,10);
                                        else if(lastBill == null) lastBill = "No bills yet";

                                        String initials   = (fname.length()>0 ? String.valueOf(fname.charAt(0)) : "")
                                                          + (lname.length()>0 ? String.valueOf(lname.charAt(0)) : "");
                                        String avaCls     = avatarClasses[(rowIdx-1) % avatarClasses.length];
                                        boolean hasPending = pending > 0;

                                        /* Usage bar width: capped at 100%, relative to 1000 L baseline */
                                        int barPct = Math.min((int)((units / 1000.0) * 100), 100);
                                        boolean highUsage = units > 800;
                            %>
                                <tr class="res-row" data-status="<%=hasPending ? "pending" : "paid"%>">
                                    <td style="color:#94a3b8;font-size:0.8rem;font-weight:600;"><%=rowIdx%></td>

                                    <!-- Name + meta -->
                                    <td>
                                        <div class="user-cell">
                                            <div class="user-ava <%=avaCls%>"><%=initials.toUpperCase()%></div>
                                            <div class="user-detail">
                                                <div class="uname"><%=fname%> <%=lname%></div>
                                                <div class="umeta">@<%=uname%> &nbsp;·&nbsp; <%=billCnt%> bill(s)</div>
                                            </div>
                                        </div>
                                    </td>

                                    <!-- Meter -->
                                    <td style="font-family:monospace;font-size:0.82rem;color:#0ea5e9;font-weight:600;"><%=meter%></td>

                                    <!-- Phone -->
                                    <td style="color:#64748b;"><%=phone%></td>

                                    <!-- Usage bar -->
                                    <td>
                                        <div class="usage-bar-wrap">
                                            <span style="font-weight:700;min-width:52px;"><%=units%> L</span>
                                            <div class="usage-bar-track">
                                                <div class="usage-bar-fill <%=highUsage ? "high" : ""%>"
                                                     style="width:<%=barPct%>%"></div>
                                            </div>
                                        </div>
                                    </td>

                                    <!-- Total billed -->
                                    <td style="font-weight:700;">Rs. <%=billed%></td>

                                    <!-- Pending amount -->
                                    <td>
                                        <% if(pending > 0) { %>
                                            <span style="font-weight:800;color:#f43f5e;">Rs. <%=pending%></span>
                                        <% } else { %>
                                            <span style="color:#10b981;font-weight:700;">&#10003; Nil</span>
                                        <% } %>
                                    </td>

                                    <!-- Last bill date -->
                                    <td style="color:#64748b;font-size:0.82rem;"><%=lastBill%></td>

                                    <!-- Status badge -->
                                    <td>
                                        <% if(pending > 0) { %>
                                            <span class="badge-pending">Pending</span>
                                        <% } else { %>
                                            <span class="badge-paid">Paid</span>
                                        <% } %>
                                    </td>

                                    <!-- Action -->
                                    <td class="no-print">
                                        <% if(pending > 0) { %>
                                            <button class="mark-paid-btn" id="mpb-<%=rsRt.getInt("id")%>"
                                                onclick="markPaid(<%=rsRt.getInt("id")%>, '<%=uname%>', this)">
                                                Mark Paid
                                            </button>
                                        <% } else { %>
                                            <button class="mark-paid-btn done" disabled>Settled</button>
                                        <% } %>
                                    </td>
                                </tr>
                            <%
                                    }
                                    conRt.close();
                                } catch(Exception ex) {
                                    out.println("<tr><td colspan='10' style='padding:30px;text-align:center;color:#94a3b8;'>" +
                                        "<i class='fas fa-database' style='margin-right:8px;'></i>" +
                                        "Could not load resident data. Check DB connection.<br><small>" + ex.getMessage() + "</small></td></tr>");
                                }
                                if(rowIdx == 0) {
                                    out.println("<tr><td colspan='10' style='padding:40px;text-align:center;color:#94a3b8;'>" +
                                        "<i class='fas fa-users' style='font-size:2rem;display:block;margin-bottom:12px;'></i>" +
                                        "No residents registered yet.<br><small>Ask users to register via the portal.</small></td></tr>");
                                }
                            %>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div id="logs-tab" class="tab-content">
                    <div class="card">
                        <h3>System Activity Logs</h3>
                        <div class="log-row"><span class="badge badge-safe">SUCCESS</span> <span><%=logTime%>: Admin Session Started.</span></div>
                        <div class="log-row"><span class="badge badge-safe">INFO</span> <span>Database connected successfully.</span></div>
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

                // Auto-open tab from URL param (e.g. after bill saved)
                (function() {
                    const urlTab = new URLSearchParams(window.location.search).get('tab');
                    if(urlTab) {
                        const el = document.querySelector('[onclick*="' + urlTab + '"]');
                        if(el) openTab(urlTab, el);
                    }
                })();

                function setTheme(themeName) {
                    document.body.className = '';
                    if (themeName !== 'default') {
                        document.body.classList.add(themeName);
                    }
                }

                function calcBill() {
                    let units = parseFloat(document.getElementById('unitInput').value) || 0;
                    let total = units * 2;
                    document.getElementById('dispAmt').innerText = total.toFixed(2);
                    document.getElementById('hidAmt').value = Math.round(total);
                    let breakdown = units > 0
                        ? units + ' L × Rs. 2 = Rs. ' + total.toFixed(2)
                        : 'Enter usage above to calculate';
                    document.getElementById('billBreakdown').innerText = breakdown;
                }

                function fillResident(sel) {
                    const opt = sel.options[sel.selectedIndex];
                    const info = document.getElementById('resInfo');
                    if(!opt.value) { info.style.display='none'; return; }
                    document.getElementById('ri-name').textContent  = opt.dataset.name  || '';
                    document.getElementById('ri-phone').textContent = opt.dataset.phone || '';
                    document.getElementById('ri-meter').textContent = opt.dataset.meter || '';
                    document.getElementById('ri-addr').textContent  = opt.dataset.addr  || '';
                    info.style.display = 'block';
                }

                function confirmBill() {
                    const resident = document.getElementById('residentSelect');
                    const units    = document.getElementById('unitInput').value;
                    const amt      = document.getElementById('dispAmt').innerText;
                    if(!resident.value) { alert('Please select a resident.'); return false; }
                    if(!units || parseInt(units) <= 0) { alert('Please enter valid usage (greater than 0).'); return false; }
                    const name = resident.options[resident.selectedIndex].dataset.name;
                    return confirm('Generate bill for ' + name + '?\n\nUsage: ' + units + ' Litres\nAmount: Rs. ' + amt + '\n\nClick OK to confirm.');
                }

                // Set today's date as default for billing date
                (function() {
                    var d = document.getElementById('billDate');
                    if(d) { d.value = new Date().toISOString().split('T')[0]; }
                })();

                function filterHistory() {
                    var input = document.getElementById("histSearch");
                    var filter = input.value.toLowerCase();
                    var table = document.getElementById("historyTable");
                    var tr = table.getElementsByTagName("tr");

                    for (var i = 1; i < tr.length; i++) {
                        var nameCell = tr[i].getElementsByClassName("cust-name")[0];
                        if (nameCell) {
                            var txtValue = nameCell.textContent || nameCell.innerText;
                            if (txtValue.toLowerCase().indexOf(filter) > -1) {
                                tr[i].style.display = "";
                            } else {
                                tr[i].style.display = "none";
                            }
                        }
                    }
                }

                /* ── DASHBOARD QUICK SEARCH ── */
                function filterDashRes() {
                    const q = document.getElementById('dashResSearch').value.toLowerCase();
                    document.querySelectorAll('#dashResTable .dash-res-row').forEach(function(row) {
                        row.style.display = row.textContent.toLowerCase().includes(q) ? '' : 'none';
                    });
                }

                /* ── RESIDENTS TAB ── */
                function filterResidents() {
                    const q = document.getElementById('resSearch').value.toLowerCase();
                    document.querySelectorAll('#resTable .res-row').forEach(function(row) {
                        const txt = row.textContent.toLowerCase();
                        row.style.display = txt.includes(q) ? '' : 'none';
                    });
                }

                let activeStatusFilter = 'all';
                function filterStatus(status, btn) {
                    activeStatusFilter = status;
                    document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('on'));
                    btn.classList.add('on');
                    document.querySelectorAll('#resTable .res-row').forEach(function(row) {
                        if (status === 'all') {
                            row.style.display = '';
                        } else {
                            row.style.display = row.dataset.status === status ? '' : 'none';
                        }
                    });
                }

                function markPaid(userId, username, btn) {
                    if(!confirm('Mark all pending bills for "' + username + '" as paid?')) return;
                    fetch('mark_paid.jsp?username=' + encodeURIComponent(username))
                        .then(function(r){ return r.text(); })
                        .then(function(res){
                            if(res.trim() === 'OK') {
                                btn.textContent = 'Settled';
                                btn.disabled = true;
                                btn.classList.add('done');
                                /* update badge in same row */
                                var row = btn.closest('tr');
                                var badge = row.querySelector('.badge-pending');
                                if(badge) { badge.className = 'badge-paid'; badge.textContent = 'Paid'; }
                                var pendingAmt = row.querySelector('td:nth-child(7)');
                                if(pendingAmt) pendingAmt.innerHTML = '<span style="color:#10b981;font-weight:700;">&#10003; Nil</span>';
                                row.dataset.status = 'paid';
                            } else {
                                alert('Could not update. Response: ' + res);
                            }
                        })
                        .catch(function(){ alert('Network error — please try again.'); });
                }

                const ctx = document.getElementById('usageChart').getContext('2d');
                new Chart(ctx, {
                    type: 'line',
                    data: {
                        labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                        datasets: [{
                            label: 'Litres Used',
                            data: [450, 520, 380, 600, 480, 700, 550],
                            borderColor: '#0ea5e9',
                            tension: 0.4
                        }]
                    }
                });
            </script>
        </body>

        </html>