package mpr.apps;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.text.SimpleDateFormat;
import java.util.Date;


public class HelloWorldJava64 {
	
	/**
	 * To be called from COBOL using:
	 *  CALL 'java.mpr.apps.HelloWorldJava64.sayHello1' using IN-DATA
	 * @param input
	 */
	public static void sayHello1(String input) {
		String methodName = (new Object(){}).getClass().getEnclosingMethod().getName();
		printHeader(methodName);

		printGreeting(methodName);

		System.out.println("The input variable input = " + input + "\n");
		
		printFooter(methodName);
	}

	/**
	 * To be called from COBOL using manual JNI calls:
	 * 
	 * @param inData A ByteBUffer we can modify
	 */
	public static void sayHello2(ByteBuffer inData) {
		String methodName = (new Object(){}).getClass().getEnclosingMethod().getName();
		printHeader(methodName);
		try{
			printGreeting(methodName);

			// Make a copy of the contents of IN-DATA using the inData object 
			inData.position(0);
			int inDataLenght = inData.capacity();
			byte[] userBytes = new byte[inDataLenght];
			inData.get(userBytes);
			
			String transactionData = new String(userBytes, "Cp1047");
			System.out.println("Transaction data: " + transactionData);

			// Modify the contents of IN-DATA using the inData object
			inData.position(0);
			inData.put((new String("Java changed this!").getBytes("Cp1047")));
		}
		catch(IOException ioe){
		  System.out.println(ioe);
		}

		printFooter(methodName);
		System.out.println(" ");
	}

	
	/**
	 * Print a greeting and the name of the method passed as input.
	 * @param methodName
	 */
	private static void printGreeting(String methodName){
		System.out.println("Hello from Java!!");
		System.out.println("Inside Java method: " + methodName);
	}


	/**
	 * Print a header block of text using the passed text.
	 * @param text the text to include in the header block.
	 */
	private static void printHeader(String text) {
		printAsteriskBlock(text + " : Entry");
		
	}

	/**
	 * Print a footer block of text using the passed text.
	 * @param text the text to include in the footer block.
	 */
	private static void printFooter(String text) {
		printAsteriskBlock(text + " : Exit");
	}

	/**
	 * Print text surounded by asterisks.
	 * @param text the text to suround with asterisks.
	 */
	private static void printAsteriskBlock(String text) {
		System.out.println(" ");
		System.out.println("******************************************************");
		System.out.println("***  " + text);
		System.out.println("******************************************************");
		System.out.println(" ");
	}



	
	public static void main(String args[]) {
		sayHello1("Carlos says Hi. 123456789*123456789*");

		// String sampleData = "Carlos says Hi. 123456789*123456789*";
		// byte[] sampleDataAsByteArray = sampleData.getBytes();
		// ByteBuffer inData = ByteBuffer.allocate(sampleDataAsByteArray.length);
		// inData.position(0);
		// inData.put(sampleDataAsByteArray);
		// sayHello2(inData);
		// 
		// inData.position(0);
		// int inDataLenght = inData.capacity();
		// byte[] userBytes = new byte[inDataLenght];
		// inData.get(userBytes);
		// // $CA
		// System.out.println("$CA original: \n" +sampleData);
		// System.out.println("$CA modified: \n" + new String(userBytes));
		// // $CA
	}
}