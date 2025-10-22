// src/test/java/com/example/hello/AppTest.java
package com.example.hello;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class AppTest {
    @Test void greet_default_whenNameBlank() {
        assertEquals("Hello, world!", App.greet(""));
    }
    @Test void greet_personalized() {
        assertEquals("Hello, Alice!", App.greet("Alice"));
    }
}