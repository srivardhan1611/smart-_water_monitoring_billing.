<%@ page import="java.sql.*, com.water.DBConnection" %>
<%
    // Admin-only guard
    HttpSession s = request.getSession(false);
    if(s == null || !"ADMIN".equals(s.getAttribute("role"))) {
        response.setStatus(403);
        out.print("FORBIDDEN");
        return;
    }

    response.setContentType("text/plain");

    String username = request.getParameter("username");
    if(username == null || username.trim().isEmpty()) {
        out.print("ERROR: No username");
        return;
    }

    try {
        Connection con = DBConnection.getConnection();
        if(con == null) {
            out.print("ERROR: DB connection failed");
            return;
        }

        PreparedStatement ps = con.prepareStatement(
            "UPDATE usage_records SET is_paid = 1 WHERE customer_name = ? AND is_paid = 0"
        );
        ps.setString(1, username.trim());
        int rows = ps.executeUpdate();
        con.close();

        out.print("OK");

    } catch(Exception e) {
        out.print("ERROR: " + e.getMessage());
    }
%>
