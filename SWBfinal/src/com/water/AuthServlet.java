package com.water;

import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;
import java.sql.*;
import java.net.URLEncoder;

public class AuthServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Safe null check before .trim()
        String username = request.getParameter("username");
        String password = request.getParameter("password");

        if (username == null || password == null ||
            username.trim().isEmpty() || password.trim().isEmpty()) {
            response.sendRedirect("login.html?error=empty");
            return;
        }

        username = username.trim();
        password = password.trim();

        // ----- HARDCODED ADMIN (no DB needed) -----
        if (username.equals("admin") && password.equals("admin")) {
            HttpSession session = request.getSession();
            session.setAttribute("user", "admin");
            session.setAttribute("role", "ADMIN");
            session.setAttribute("displayName", "Administrator");
            response.sendRedirect("dashboard.jsp");
            return;
        }

        // ----- DB USER CHECK -----
        Connection con = null;
        try {
            con = DBConnection.getConnection();

            if (con == null) {
                response.sendRedirect("login.html?error=db");
                return;
            }

            String sql = "SELECT id, first_name, last_name, username, password " +
                         "FROM users WHERE username = ? AND is_active = 1";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, username);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                String storedPass = rs.getString("password");
                // Plain text comparison — passwords stored as-is in DB
                if (password.equals(storedPass)) {
                    int    uid   = rs.getInt("id");
                    String fname = rs.getString("first_name");
                    String lname = rs.getString("last_name");

                    HttpSession session = request.getSession(true);
                    session.setAttribute("user",        username);
                    session.setAttribute("role",        "USER");
                    session.setAttribute("userId",      Integer.valueOf(uid));
                    session.setAttribute("displayName", fname + " " + lname);

                    rs.close(); ps.close(); con.close(); con = null;
                    response.sendRedirect("user_dashboard.jsp");
                    return;
                }
            }
            rs.close(); ps.close();

        } catch (Exception e) {
            e.printStackTrace();
            try {
                String msg = e.getMessage() != null ? e.getMessage() : "unknown error";
                response.sendRedirect("login.html?error=exception&msg=" +
                    URLEncoder.encode(msg, "UTF-8"));
            } catch (Exception ex) {
                response.sendRedirect("login.html?error=exception");
            }
            return;
        } finally {
            if (con != null) { try { con.close(); } catch (Exception ignore) {} }
        }

        response.sendRedirect("login.html?error=invalid");
    }
}
