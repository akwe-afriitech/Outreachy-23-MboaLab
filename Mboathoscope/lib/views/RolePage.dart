import 'package:flutter/material.dart';
import 'package:mboathoscope/views/buttons/CustomButton.dart';
import 'package:mboathoscope/views/homePage.dart';
import '../models/User.dart';


class RolePage extends StatelessWidget {
  static const id = 'RolePage';
  final CustomUser user;
  const RolePage({Key? key, required this.user}) : super(key: key);


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xffF3F7FF),
      body: Column(
        children: [
           SizedBox(
            height: MediaQuery.of(context).size.height* 0.1,
          ),
          Padding(
            padding: EdgeInsets.all(5.0),
            // padding: const EdgeInsets.only(left: 26,right: 26, top: 87),
            child: Image.asset(
              'assets/images/img_role.png',
              height: MediaQuery.of(context).size.height* 0.58,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 23, right: 23),
            child: Text(
              'Please select your role',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 25,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 35, right: 20, left: 20),
            child: SizedBox(
              width: MediaQuery.of(context).size.width* 0.9,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   CustomButton(
                    txt: 'Transmitter',
                  ),
                   SizedBox(
                    width:  MediaQuery.of(context).size.width* 0.2,
                  ),
                   CustomButton(
                    txt: ' Receiver  ',
                  )
                ],
              ),
            ),
          ),
          
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 0, top: 30),
            child: GestureDetector(
              onTap: (){
                ///
                Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(user: this.user)));
              },
              child: Container(
                width: 120,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  // color: Colors.redAccent,
                  gradient: const LinearGradient(
                    colors: [Color(0xffC5D7FE),Colors.blueAccent],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "Next ",
                        style: TextStyle(color: Colors.black,fontSize: 20)
                      ),
                      WidgetSpan(
                        child: Icon(Icons.arrow_forward_ios, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}