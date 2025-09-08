import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:testapp3/animals.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {

  final SearchController=TextEditingController();
  void do_something(){
    setState(() {
      String Input=SearchController.text;
      print(Input);
    });
  }
  @override
  void initState(){
    super.initState();
    SearchController.addListener(do_something);
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(11.0),
            child: Text(
              "Adopt_a_Pet",
              style: TextStyle(
                fontSize:  40
              ),
            ),
          ),
          TextField(
            controller: SearchController,
            decoration: InputDecoration(border: OutlineInputBorder(), labelText: 'Find_A_Pet'),
          ),
          Text(SearchController.text),
          Container(
            height: 650,
            child: GridView.count(
                crossAxisCount: 2,
              children: [
                Container(
                  padding:EdgeInsets.all(6) ,
                  height: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>AnimalScreen(
                        name: 'Fennec Fox',
                        description: 'Big ears small animal',
                        bigImage: 'https://img.freepik.com/premium-photo/fennec-fox-with-large-ears_636537-454429.jpg',
                        images: [
                          'https://img.freepik.com/premium-photo/fennec-fox-with-large-ears_636537-454429.jpg',
                          'https://encrypted-tbn3.gstatic.com/images?q=tbn:ANd9GcT9KMYpKPi8BuCSskPzl6m6vq8fuiMZ64oOChBBgvGgmV5QaTKeEUxQWcpIlym7Bus2h5WwF6Cgb_aTvmPrRvUEww',
                          'https://animals.sandiegozoo.org/sites/default/files/2016-10/fennec_fox_0.jpg',
                          'https://images.exoticanimalsforsale.net/uploads/672E30C4-F874-4586-A927-79EE8BAAEAC1-1000x1000-8VzVeA6I9b.jpeg',
                          'https://www.thesprucepets.com/thmb/hIkuZJNLBxjcslOAUxNnwgqj1HU=/6187x0/filters:no_upscale():strip_icc()/about-fennec-foxes-as-pets-1236778-hero-e5e8ebfbd07b4516a2508ea59b8d461b.JPG',
                          'https://img.freepik.com/premium-photo/fennec-fox-with-large-ears_636537-454429.jpg',
                        ],
                      )));
                    },
                    clipBehavior: Clip.antiAlias,// <--add this
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xEDAABAFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0), // <--add this
                      ),
                      padding: EdgeInsets.zero, // <--add this
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.network(
                        'https://media.wired.com/photos/593261cab8eb31692072f129/master/pass/85120553.jpg',
                        fit: BoxFit.cover,
                        width: 150,
                        height: 150,
                      ),

                    ),
                  ),
                ),
                Container(
                  padding:EdgeInsets.all(6),
                  height: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>AnimalScreen(
                        name: 'Penguin',
                        description: 'Furry',
                        bigImage: 'https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcQ28n4lxQVmopUgEYYHBzQkeQQIIXe0z057rigOGyzYf3sCa7QLr1tvsRILvlZlSAOjxHjZy7TMNH89tTgxqbnXJA',
                        images: [
                          'https://i.pinimg.com/474x/96/66/be/9666be9540223dd0489471004131c295.jpg',
                          'https://www.cabq.gov/artsculture/biopark/news/10-cool-facts-about-penguins/@@images/1a36b305-412d-405e-a38b-0947ce6709ba.jpeg',
                          'https://thumbs.dreamstime.com/b/cute-baby-penguin-toy-standing-snow-christmas-time-adorable-baby-penguin-soft-toy-standing-artificial-snow-356795308.jpg',
                              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR4y2xjL-1212d6NWthNTXC9WDu0uNQnI3kO7JI7Wrp5acMs9i9vGY7RoU7G3WR7ezSLTI&usqp=CAU',
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRRipL2jV3lOmzGyQu5MzUDOldLGklfN0CYJg&s',
                          'https://i.redd.it/scb530bd10y11.png',


                        ],
                      )));
                    },
                    clipBehavior: Clip.antiAlias,// <--add this
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xEDAABAFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0), // <--add this
                      ),
                      padding: EdgeInsets.zero, // <--add this
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.network(
                        'https://compote.slate.com/images/73f0857e-2a1a-4fea-b97a-bd4c241c01f5.jpg',
                        fit: BoxFit.cover,
                        width: 150,
                        height: 150,
                      ),

                    ),
                  ),
                ),
                Container(
                  padding:EdgeInsets.all(6),
                  height: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>AnimalScreen(
                        name: 'Panda',
                        description: 'Tiny and Furry',
                        bigImage: 'https://yt3.googleusercontent.com/ytc/AIdro_moEyBQHVnkITSiWvL7PcgCH4SJbgNKNrr7HlZAeEVIog=s900-c-k-c0x00ffffff-no-rj',
                        images: [
                          'https://www.shutterstock.com/image-photo/baby-panda-sleeping-on-tree-600nw-2549360951.jpg',
                          'https://cdn1.tedsby.com/storage/6/2/3/623782/sewing-pattern-panda-teddy-bear-pdf.jpg',
                              'https://cf-img-a-in.tosshub.com/sites/visualstory/wp/2023/10/wp2883597.jpg?size=*:900',
                          'https://www.shutterstock.com/image-photo/playful-happy-panda-china-600nw-1390386575.jpg',
                          'https://static01.nyt.com/images/2022/07/05/science/30tb-panda/30tb-panda-articleLarge.jpg?quality=75&auto=webp&disable=upscale',
                          'https://i.pinimg.com/736x/47/58/64/475864e92bb226307703fe7a8c72cc37.jpg',

                        ],
                      )));
                    },
                    clipBehavior: Clip.antiAlias,// <--add this
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xEDAABAFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0), // <--add this
                      ),
                      padding: EdgeInsets.zero, // <--add this
                    ), child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSmXhtdddYGmdbTHZ4YsmOp8lw2pS46M51sDw&s',
                          fit: BoxFit.cover,
                          width: 150,
                          height: 150,
                        ),

                    ),
                  ),
                ),
                Container(
                  padding:EdgeInsets.all(6),
                  height: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>AnimalScreen(
                        name: 'cat',
                        description: 'smart and fluffy',
                        bigImage: 'https://cdn.britannica.com/87/205187-050-BEE2B338/tapetum-lucidum-light-retina-night-vision-vertebrates.jpg',
                        images: [
                          'https://pethelpful.com/.image/w_3840,q_auto:good,c_fill,ar_4:3/MTk2NzY3MjA5ODc0MjY5ODI2/top-10-cutest-cat-photos-of-all-time.jpg',
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTxMKDUkpmxTQa70zannlbBKUM73RBskpiEV_265mKc1mbCIfAZLBKeT1cClrq4_j_Gl44&usqp=CAU',
                          'https://thumbs.dreamstime.com/b/small-cat-8301434.jpg',
                          'https://i.pinimg.com/736x/b6/a6/d5/b6a6d50de7eb36065b98ebd254d46cd5.jpg',
                          'https://images.ctfassets.net/ub3bwfd53mwy/5WFv6lEUb1e6kWeP06CLXr/acd328417f24786af98b1750d90813de/4_Image.jpg?w=750',
                          'https://i.pinimg.com/564x/8b/3e/c3/8b3ec340e695a24abf5a52d90f70916a.jpg',

                        ],
                      )));
                    },
                    clipBehavior: Clip.antiAlias,// <--add this
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xEDAABAFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0), // <--add this
                      ),
                      padding: EdgeInsets.zero,
                      //// <--add this
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.network(
                        'https://static.independent.co.uk/s3fs-public/thumbnails/image/2013/01/24/12/v2-cute-cat-picture.jpg',
                        fit: BoxFit.cover,
                        width: 150,
                        height: 150,
                      ),

                    ),
                  ),
                ),
                Container(
                  padding:EdgeInsets.all(6),
                  height: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>AnimalScreen(
                        name: 'Baby Goat',
                        description: 'Super tiny and ai generated',
                        bigImage: 'https://a-z-animals.com/media/2021/12/lovely-white-baby-goat-running-on-grass-picture-id1281182694-1024x535.jpg',
                        images: [
                          'https://i.redd.it/1ct920dhv4951.jpg',
                          'https://i.redd.it/kkml6qsivsf71.jpg',
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRmurKoPVJf5I_-POSl4hlI-PFhCBDWerGZDA&s',
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRROi7Qe4JScbIFkuMUgjGBduHWza26-3HCXw&s',
                          'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/095209d1-477a-460c-bea8-f40bc96d0edf/dg48q1u-5fce11f8-bd84-4971-8a0a-d9f3930832e1.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiJcL2ZcLzA5NTIwOWQxLTQ3N2EtNDYwYy1iZWE4LWY0MGJjOTZkMGVkZlwvZGc0OHExdS01ZmNlMTFmOC1iZDg0LTQ5NzEtOGEwYS1kOWYzOTMwODMyZTEuanBnIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.fJ-tQokG9A9dy1AYyqOagwlsT83yZjK_T0Bmo2D-KYo',
                          'https://media-cdn.tripadvisor.com/media/photo-s/19/66/78/6b/the-baby-goat-on-the.jpg',
                        ],
                      )));
                    },
                    clipBehavior: Clip.antiAlias,// <--add this
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xEDAABAFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0), // <--add this
                      ),
                      padding: EdgeInsets.zero, // <--add this
                    ),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRexXYRih2z-Nl2V_5l-kHtAbFFxado5n0c8w&s',
                          fit: BoxFit.cover,
                          width: 150,
                          height: 150,
                        ),
                    ),
                  ),
                ),
                Container(
                  padding:EdgeInsets.all(6),
                  height: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>AnimalScreen(
                        name: 'dog',
                        description: 'funny dog and best friend is a duck',
                        bigImage: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR7NE4ik0r1KOaxl-Goc1zQ-o-g5xEg_lLB3RLQbyxV7waQh8t16w2KJoocNJkRTPM6ht8&usqp=CAU',
                        images: [
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSmF4QaexQAjyGPAjpDN5MhVCNeqLlvk6Jzgw&s',
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRYNxX3lTVilFxhkyDVeICce49_1pyTxQK4iw&s',
                          'https://i.imgur.com/d72BVTc.jpg',
                          'https://www.shutterstock.com/image-photo/little-friends-shih-tzu-puppy-600nw-1821195557.jpg',
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTVmk0OVYU-f-HO3yDuT-MdE97lSLBjFq1zAg&s',
                          'https://i.pinimg.com/474x/d4/5d/26/d45d2671a8f6d35e352e400e6dd6113c.jpg',
                        ],
                      )));
                    },
                    clipBehavior: Clip.antiAlias,// <--add this
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xEDAABAFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0), // <--add this
                      ),
                      padding: EdgeInsets.zero, // <--add this
                    ),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                            'https://i.pinimg.com/videos/thumbnails/originals/5e/2d/9f/5e2d9ffb9785c6fdc322f90f0e8b4e41.0000000.jpg',
                            fit: BoxFit.cover,
                          width: 150,
                          height: 150,
                    ),


                    ),
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
