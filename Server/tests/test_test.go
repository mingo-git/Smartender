package tests

import (
    "testing"
    "app/internal/utils"
)

// TestAdd tests the Add function.
func TestAdd(t *testing.T) {
    // Define test cases
    testCases := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"Add positives", 2, 3, 5},
        {"Add negatives", -1, -1, -2},
        {"Add positive and negative", 5, -3, 2},
        {"Add zeros", 0, 0, 0},
    }

    // Iterate over test cases
    for _, tc := range testCases {
        t.Run(tc.name, func(t *testing.T) {
            result := utils.Add(tc.a, tc.b)
            if result != tc.expected {
                t.Errorf("Add(%d, %d) = %d; want %d", tc.a, tc.b, result, tc.expected)
            }
        })
    }
}