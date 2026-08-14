import 'package:flutter/material.dart';


class HomePage extends StatelessWidget {

  const HomePage({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,


      appBar: AppBar(

        title: const Text(
          "AI Friend",
        ),

        centerTitle: true,

      ),


      body: Center(

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,


          children: [


            // AI头像

            CircleAvatar(

              radius: 60,

              child: Icon(

                Icons.smart_toy,

                size: 70,

              ),

            ),



            const SizedBox(height: 30),



            // AI名字

            const Text(

              "小雪",

              style: TextStyle(

                fontSize: 32,

                fontWeight:
                    FontWeight.bold,

              ),

            ),



            const SizedBox(height: 15),



            //介绍

            const Text(

              "你的AI朋友",

              style: TextStyle(

                fontSize: 18,

              ),

            ),



            const SizedBox(height: 10),



            const Text(

              "今天想聊什么？",

              style:

                  TextStyle(

                    fontSize: 16,

                  ),

            ),



            const SizedBox(height: 40),



            //按钮

            ElevatedButton(

              onPressed: (){


                print("进入聊天");


              },


              child:

              const Text(

                "开始聊天",

              ),

            )

          ],


        ),

      ),


    );

  }

}