package foo.bar;

import parent.FooBarParent;

public class FooBar extends FooBarParent {

    public FooBar(){
    }

    public static void main(String[] args){
        System.out.println("foo.FooBar.main");
        System.out.println("The FooBar class has been run with the following arguments:");
        for (int i = 0; i < args.length; i++) {
            System.out.println("arg = " + args[i]);
        }
        System.out.println("Antwrap JVM Arg: " + System.getProperty("antwrap"));
        System.exit(0);
    }
}
