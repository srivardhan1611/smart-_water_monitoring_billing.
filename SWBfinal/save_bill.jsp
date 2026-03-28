<%@ page import="java.sql.*, java.net.URLEncoder, com.water.DBConnection" %>
<%
    // Admin-only guard
    HttpSession s = request.getSession(false);
    if(s == null || !"ADMIN".equals(s.getAttribute("role"))) {
        response.sendRedirect("login.html");
        return;
    }

    String customerName = request.getParameter("customer_name");
    String unitsStr     = request.getParameter("units");
    String billAmtStr   = request.getParameter("bill_amount");
    String billDateStr  = request.getParameter("bill_date");

    // Validation
    if(customerName == null || customerName.trim().isEmpty()) {
        response.sendRedirect("dashboard.jsp?tab=billing&err=" + URLEncoder.encode("No resident selected.", "UTF-8"));
        return;
    }

    int units   = 0;
    int billAmt = 0;
    try { units   = Integer.parseInt(unitsStr.trim());   } catch(Exception e) {}
    try { billAmt = Integer.parseInt(billAmtStr.trim()); } catch(Exception e) {}

    if(units <= 0) {
        response.sendRedirect("dashboard.jsp?tab=billing&err=" + URLEncoder.encode("Usage must be greater than 0.", "UTF-8"));
        return;
    }
    // Recalculate to prevent tampering
    billAmt = units * 2;

    try {
        Connection con = DBConnection.getConnection();
        if(con == null) {
            response.sendRedirect("dashboard.jsp?tab=billing&err=" + URLEncoder.encode("Database connection failed.", "UTF-8"));
            return;
        }

        String sql;
        PreparedStatement ps;

        // Use provided date or NOW()
        if(billDateStr != null && !billDateStr.trim().isEmpty()) {
            sql = "INSERT INTO usage_records(customer_name, units, bill_amount, bill_date, is_paid) VALUES(?,?,?,?,0)";
            ps  = con.prepareStatement(sql);
            ps.setString(1, customerName.trim());
            ps.setInt(2, units);
            ps.setInt(3, billAmt);
            ps.setString(4, billDateStr.trim());
        } else {
            sql = "INSERT INTO usage_records(customer_name, units, bill_amount, bill_date, is_paid) VALUES(?,?,?,NOW(),0)";
            ps  = con.prepareStatement(sql);
            ps.setString(1, customerName.trim());
            ps.setInt(2, units);
            ps.setInt(3, billAmt);
        }

        ps.executeUpdate();
        con.close();
        response.sendRedirect("dashboard.jsp?tab=billing&bill=saved");

    } catch(Exception e) {
        e.printStackTrace();
        try {
            response.sendRedirect("dashboard.jsp?tab=billing&err=" + URLEncoder.encode(e.getMessage() != null ? e.getMessage() : "Unknown error", "UTF-8"));
        } catch(Exception ex) {
            response.sendRedirect("dashboard.jsp?tab=billing");
        }
    }
%>
