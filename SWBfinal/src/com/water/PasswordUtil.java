package com.water;

public class PasswordUtil {
    public static boolean checkPassword(String inputPassword, String storedPassword) {
        return inputPassword.equals(storedPassword);
    }
}
