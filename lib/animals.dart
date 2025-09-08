import 'package:flutter/material.dart';

class AnimalScreen extends StatelessWidget {
  final String name;
  final String description;
  final String bigImage;
  final List<String> images;

  const AnimalScreen({
    super.key,
    required this.name,
    required this.description,
    required this.bigImage,
    required this.images
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> mini=[];
    for(int i=0;i< images.length;i=i+1){
      //Image.network(images[i])
      mini.add(Container(
        padding: EdgeInsets.all(0.2),
        width: 100,
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
        ),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.network(images[i], fit: BoxFit.cover,)
        ),
      ),);
    }
    print(mini);
    return Scaffold(
      appBar:AppBar(
        title: Text(name),
      ),
      body: ListView(
        children: [
          Container(
            padding: EdgeInsets.all(0.2),
            width: 100,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
            ),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.network(bigImage, fit: BoxFit.cover,)
            ),
          ),
          Text(
              description,
            style: TextStyle(
              fontSize:30
            ),

          ),
          Container(
            height: 500,
            child: GridView.count(
                crossAxisCount: 3,
                children:mini,
            ),
          ),
        ],
      )
    );
  }
}

