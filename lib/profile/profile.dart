import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testapp3/books/book_tile.dart';
import 'package:testapp3/components/xp_bar.dart';
import 'package:testapp3/design_wrapper.dart';
import 'package:testapp3/profile/edit_profile.dart';

import '../homepage.dart';
import '../util/firebase_utils.dart';

class ProfileScreen extends StatefulWidget {
  final String friendCode;

  const ProfileScreen({super.key, required this.friendCode});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isOwnProfile = false;
  bool isFriends = false;

  void checkIfOwnProfile() async {
    final same = widget.friendCode == await FirebaseUtils.getCurrentUserFriendCode();

    setState(() {
      isOwnProfile = same;
    });
  }

  void checkIfFriends() async {
    final currentUser = await FirebaseUtils.getCurrentUserFriendCode();
    final friends = await FirebaseUtils.isFriends(currentUser!, widget.friendCode);

    setState(() {
      isFriends = friends;
    });
  }

  void addFriend() async {
    final currentUser = await FirebaseUtils.getCurrentUserFriendCode();

    await FirebaseUtils.addFriend(currentUser!, widget.friendCode);
    setState(() {
      checkIfFriends();
    });
  }

  void removeFriend() async {
    final currentUser = await FirebaseUtils.getCurrentUserFriendCode();

    await FirebaseUtils.removeFriend(currentUser!, widget.friendCode);
    setState(() {
      checkIfFriends();
    });
  }

  void getCurrentXpAndLevel() async {

  }

  @override
  void initState(){
    super.initState();
    checkIfOwnProfile();
    checkIfFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          children: [
            Container(
              height:250 , width: 333,
              margin: EdgeInsets.only(top: 35, bottom:30),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Color(0xfff2f2f7)
              ),
              child: FutureBuilder(
                future: FirebaseUtils.getUserData(widget.friendCode),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No results"));
                  }
                  final userData = snapshot.data!;
                  return Row(
                    children: [
                      Expanded(
                        flex: 40,
                        child: Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 70,
                                backgroundImage: NetworkImage(userData["profilePic"]),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text(userData["username"],style: TextStyle(fontSize: 20,fontFamily: "Voltaire"),),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(width: 27,),
                                  Text(userData["friendCode"],style: TextStyle(fontSize: 18,fontFamily: "Voltaire"),),
                                  IconButton(onPressed: () {
                                    Clipboard.setData(ClipboardData(text: widget.friendCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Copied to clipboard!")),
                                    );
                                    }, icon: Icon(Icons.copy))
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: SizedBox(

                        ),
                        flex: 3,
                      ),
                      Expanded(
                        flex: 35,
                        child:Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${userData["books"].length} Books Read",style: TextStyle(height:1.2,fontSize: 30,fontFamily: "Voltaire"),),
                              SizedBox(height: 7,),
                              Text("Level ${userData["level"]}",style: TextStyle(fontSize: 30,fontFamily: "Voltaire",fontWeight: FontWeight.bold),),
                              TextButton(
                                  onPressed: (){
                                    if(isOwnProfile){
                                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => homepage(initialpage: 1)));
                                    }
                                  },
                                  style: ButtonStyle(
                                    minimumSize: WidgetStateProperty.all(Size.zero), // Removes default minimum size
                                    padding: WidgetStateProperty.all(EdgeInsets.zero), // Removes default padding
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text("${userData["friends"].length} friends",style: TextStyle(color: Color(0xff0088FF)),)
                              ),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                      context: context, 
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text("${userData["username"]}'s Bio"),
                                          content: Text(userData["bio"]),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: Text("Close"),
                                            ),
                                          ],
                                        );
                                      });
                                },
                                  child: SizedBox(width: double.infinity, child: Text(userData["bio"], maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16,fontFamily: "Voltaire"),))
                              ),



                            ],
                          ),
                      ),
                      Expanded(
                        flex: 20,
                        child: Center(
                          child: Column(
                            children: [
                              IconButton(
                                  onPressed: () async {
                                    if(isOwnProfile){
                                      final updated = await Navigator.push(
                                          context, MaterialPageRoute(
                                          builder: (_) => DesignWrapper(
                                              wrappedWidget: EditProfilePage(
                                                userData: userData,
                                                friendCode: userData["friendCode"],
                                              )
                                          )
                                      ));
                                      if(updated != null && updated){
                                        setState(() {});
                                      }
                                    } else if (isFriends){
                                      removeFriend();
                                    } else {
                                      addFriend();
                                    }
                                  },
                                  icon: Icon((isOwnProfile) ? Icons.settings : (isFriends) ? Icons.person_off : Icons.person_add)
                              )
                            ],
                          ),
                        ),
                      ),

                    ],
                  );
                }
              ),
            ),
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: FutureBuilder(
                    future: FirebaseUtils.getUserData(widget.friendCode),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text("No results"));
                      }
                      final userData = snapshot.data!;
                      return XPBar(level: userData["level"], xp: userData["xp"], nextLevelXp: userData["next_level_xp"]);
                    }
                ),
              ),
            ),
            Text("Saved Books",style: TextStyle(fontSize: 20,fontFamily: "Voltaire"),),
            Expanded(
              flex: 30,
                child: FutureBuilder(
                    future: FirebaseUtils.getUserBooks(widget.friendCode),
                    builder: (context, snapshot) {
                      if(snapshot.connectionState == ConnectionState.waiting){
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError){
                        return Center(
                            child: Text('Error: ${snapshot.error}')
                        );
                      }

                      final querySnapshot = snapshot.data;
                      if (querySnapshot == null || querySnapshot.isEmpty) {
                        return Center(child: Column(
                          children: [
                            Text("No books saved so far."),
                            TextButton(
                                onPressed: (){
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>homepage(initialpage: 2)));
                                },
                                style: ButtonStyle(
                                  minimumSize: WidgetStateProperty.all(Size.zero), // Removes default minimum size
                                  padding: WidgetStateProperty.all(EdgeInsets.zero), // Removes default padding
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: (!isOwnProfile) ? Container() : Text("Tap here to add a book!",style: TextStyle(color: Color(0xff0088FF)),)
                            ),
                          ],
                        ));
                      }

                      return ListView.builder(
                        itemCount: querySnapshot.length,
                        itemBuilder: (context, index) {
                          final book=querySnapshot[index];
                          return BookTile(bookImageurl: book["imageurl"], title: book["title"], author: book["author"], pages:book["pages"] , shopurl: "shopurl" , grade: '',review: true,rating: book["rating"],ReviewText: book["review"],);
                        },
                      );
                    }
                )
            )
          ],
        ),
      );
  }

}
