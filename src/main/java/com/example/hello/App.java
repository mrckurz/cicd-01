// src/main/java/com/example/hello/App.java
package com.example.hello;

public class App {
    public static void main(String[] args) {
        System.out.println("Hello, Java CI!");
    }
    public static String greet(String name) {
        if (name == null || name.isBlank()) return "Hello, world!";
        return "Hello, " + name + "!";
    }
}