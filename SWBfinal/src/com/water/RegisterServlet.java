package com.water;

import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;
import java.sql.*;
import java.net.URLEncoder;

public class RegisterServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String firstName = request.getParameter("firstName").trim();
        String lastName  = request.getParameter("lastName").trim();
        String email     = request.getParameter("email").trim();
        String username  = request.getParameter("username").trim();
        String phone     = request.getParameter("phone").trim();
        String address   = request.getParameter("address").trim();
        String password  = request.getParameter("password");
        String confirm   = request.getParameter("confirmPassword");

        // Validation
        if (!password.equals(confirm)) {
            response.sendRedirect("register.html?reg_error=" + URLEncoder.encode("Passwords do not match.", "UTF-8"));
            return;
        }
        if (password.length() < 6) {
            response.sendRedirect("register.html?reg_error=" + URLEncoder.encode("Password must be at least 6 characters.", "UTF-8"));
            return;
        }

        try {
            Connection con = DBConnection.getConnection();
            if (con == null) {
                response.sendRedirect("register.html?reg_error=" + URLEncoder.encode("Database error. Please try later.", "UTF-8"));
                return;
            }

            // Check duplicate username or email
            PreparedStatement check = con.prepareStatement(
                "SELECT id FROM users WHERE username = ? OR email = ?");
            check.setString(1, username);
            check.setString(2, email);
            ResultSet rs = check.executeQuery();
            if (rs.next()) {
                con.close();
                response.sendRedirect("register.html?reg_error=" + URLEncoder.encode("Username or email already exists. Please choose different credentials.", "UTF-8"));
                return;
            }

            // Insert user — meter_no generated server-side
            String meterNo = "MTR" + System.currentTimeMillis();
            String sql = "INSERT INTO users (first_name, last_name, email, username, phone, address, password, meter_no, role, is_active, created_at) " +
                         "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'USER', 1, NOW())";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, firstName);
            ps.setString(2, lastName);
            ps.setString(3, email);
            ps.setString(4, username);
            ps.setString(5, phone);
            ps.setString(6, address);
            ps.setString(7, password);
            ps.setString(8, meterNo);
            ps.executeUpdate();
            con.close();

            // Redirect to login with success message
            response.sendRedirect("login.html?registered=true");

        } catch (Exception e) {
            e.printStackTrace();
            try {
                response.sendRedirect("register.html?reg_error=" + URLEncoder.encode("Registration failed: " + e.getMessage(), "UTF-8"));
            } catch (Exception ex) { ex.printStackTrace(); }
        }
    }
}
