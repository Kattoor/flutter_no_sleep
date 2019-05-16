import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_no_sleep/reddit_icons.dart';
import 'package:http/http.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fancy_bottom_navigation/fancy_bottom_navigation.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Nosleep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: PostsPage(title: 'Flutter Nosleep'),
    );
  }
}

class PostsPage extends StatefulWidget {
  PostsPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _PostsPageState createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  List<dynamic> _posts;
  int _currentPage = 0;

  void fetch(String category) {
    get('https://www.reddit.com/r/nosleep/' + category + '.json')
        .then((response) {
      List<dynamic> posts = jsonDecode(response.body)['data']['children']
          .map((child) => child['data'])
          .map((data) => {
                'title': data['title'],
                'content': data['selftext'],
                'author': data['author'],
                'upvotes': data['ups'],
                'allAwardings': data['all_awardings'],
                'created': data['created'],
                'amountofComments': data['num_comments'],
                'link': data['url'],
                'createdUTC': data['created_utc'],
              })
          .toList();

      setState(() {
        _posts = posts;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(child: getBody()),
      bottomNavigationBar: FancyBottomNavigation(
        tabs: [
          TabData(iconData: Reddit.hot, title: "Hot"),
          TabData(iconData: Reddit.new_icon, title: "New"),
          TabData(iconData: Reddit.top, title: "Top"),
        ],
        onTabChangedListener: (position) {
          setState(() {
            _posts = [];
            fetch(['hot', 'new', 'top'][position]);
            _currentPage = position;
          });
        },
      ),
    );
  }

  Widget getBody() {
    if (_posts == null || _posts.length == 0)
      return CircularProgressIndicator();

    return Container(
        padding: EdgeInsets.only(top: 5),
        child: ListView.separated(
          itemBuilder: (context, index) => ListTile(
                leading: Column(
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up,
                      size: 20,
                      color: Color.fromARGB(255, 255, 106, 50),
                    ),
                    Text(
                      _posts[index]['upvotes'].toString(),
                      style:
                          TextStyle(color: Color.fromARGB(255, 255, 106, 50)),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Color.fromARGB(255, 141, 168, 255),
                    ),
                  ],
                ),
                title: Text(_posts[index]['title']),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => Scaffold(
                            body: Markdown(
                              data: _posts[index]['content'],
                              padding: EdgeInsets.fromLTRB(20, 50, 20, 50),
                            ),
                          ),
                    ),
                  );
                },
              ),
          separatorBuilder: (context, index) => Divider(),
          itemCount: _posts?.length ?? 0,
        ));
  }

  @override
  void initState() {
    super.initState();
    fetch('hot');
  }
}
