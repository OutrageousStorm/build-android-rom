/**
 * BASIC_MODULE.js -- LSPosed module template
 */

setTimeout(() => {
    Java.perform(() => {
        console.log("[Module] Loaded");
        
        const MainActivity = Java.use("com.example.app.MainActivity");
        MainActivity.onCreate.overload("android.os.Bundle").implementation = function(savedInstanceState) {
            console.log("[MainActivity] onCreate called");
            this.onCreate.call(this, savedInstanceState);
        };
        
        const Calculator = Java.use("com.example.app.Calculator");
        Calculator.add.overload("int", "int").implementation = function(a, b) {
            const result = this.add.call(this, a, b);
            console.log(`[Calculator] ${a} + ${b} = ${result}`);
            return result;
        };
        
        console.log("[Module] Hooks installed");
    });
}, 0);
