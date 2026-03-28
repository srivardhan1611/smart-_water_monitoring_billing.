package com.water;

import java.sql.Connection;
import java.sql.DriverManager;

public class DBConnection {

    public static Connection getConnection() {
        Connection con = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/water_system?useSSL=false&serverTimezone=UTC",
                "root",
                "manager"
            );
        } catch (Exception e) {
            System.out.println("DB Connection Error: " + e.getMessage());
            e.printStackTrace();
        }
        return con;
    }
}
