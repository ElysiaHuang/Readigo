import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/CreateAccount.dart';
import 'package:testapp3/util/firebase_utils.dart';

import 'get_started.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final emailController=TextEditingController();
  final passwordController=TextEditingController();

  Future<void> signIn()async {
    String email=emailController.text.trim();
    String password=passwordController.text.trim();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if(mounted){
        Navigator.pop(context);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => start_page()));
      }
    } on FirebaseAuthException catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message.toString()),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Sign In",style: TextStyle(fontSize: 25, fontFamily: "Voltaire" ),),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                  width: 360,
                child: Column(
                  children: [
                    Align(child: Text("Email",style: TextStyle(),),alignment:Alignment.centerLeft,),
                    SizedBox(
                    height: 60,
                      child: TextFormField(
                        controller: emailController,

                        decoration: const InputDecoration(
                            helperText: "",
                            focusedBorder:OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                              borderRadius: const BorderRadius.all(Radius.circular(14))
                            ),
                            border:OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                                borderRadius: const BorderRadius.all(Radius.circular(14))
                            ),
                            hintText: ''),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Try Again';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10,),
              Container(
                width: 360,
                child: Column(
                  children: [
                    Align(child: Text("Password",style: TextStyle(),),alignment:Alignment.centerLeft,),
                    SizedBox(
                         height: 60,
                      child: TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                            helperText: "",
                            focusedBorder:OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.black),
                                borderRadius: const BorderRadius.all(Radius.circular(14))
                            ),
                            border:OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                                borderRadius: const BorderRadius.all(Radius.circular(14))
                            ),
                            hintText: ''),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'TRY AGAIN!!!';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: OutlinedButton.icon(
                  onPressed: (){
                    // Validate will return true if the form is valid, or false if
                    // the form is invalid.
                    if (_formKey.currentState!.validate()) {
                      signIn();
                    }
                  },
            label: Text("Submit"),
            style: OutlinedButton.styleFrom(
                backgroundColor: Color(0xFFC0FFC0),
                foregroundColor: Color(0xFF41BF41)
            ),

          )),
              SizedBox(height: 1,),
              Text("Don't have an account?"),
              TextButton(
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>Createaccount()));
                  },
                  style: ButtonStyle(
                    minimumSize: WidgetStateProperty.all(Size.zero), // Removes default minimum size
                    padding: WidgetStateProperty.all(EdgeInsets.zero), // Removes default padding
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text("Tap Here!",style: TextStyle(color: Colors.cyan),)
              ),
              Image.asset(height: 300,"assets/images/ReadigoLogo.png")

            ],
          ),
        ),
      ),
    );
  }
}
