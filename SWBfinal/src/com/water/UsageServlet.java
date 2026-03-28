package com.water;

import java.io.*;
import javax.servlet.*;
import javax.servlet.http.*;
import java.sql.*;

public class UsageServlet extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String customer = request.getParameter("customer");
        String unitStr  = request.getParameter("units");
        int units = 0;
        if (unitStr != null && !unitStr.isEmpty()) {
            units = Integer.parseInt(unitStr);
        }
        int bill = units * 2;

        try {
            Connection con = DBConnection.getConnection();
            if (con == null) {
                response.sendRedirect("dashboard.jsp?err=db");
                return;
            }
            String sql = "INSERT INTO usage_records(customer_name, units, bill_amount, bill_date) VALUES(?,?,?,NOW())";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, customer);
            ps.setInt(2, units);
            ps.setInt(3, bill);
            ps.executeUpdate();
            con.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        response.sendRedirect("dashboard.jsp");
    }
}
