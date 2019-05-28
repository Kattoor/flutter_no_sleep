import 'dart:convert';
import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_no_sleep/AuthEvents.dart';
import 'package:flutter_no_sleep/reddit_icons.dart';
import 'package:http/http.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fancy_bottom_navigation/fancy_bottom_navigation.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:html/parser.dart';
import 'dart:math';

import 'AuthBLoC.dart';

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
  final authBloc = AuthBLoC();

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
                'short': (() {
                  var parsed = parse(
                          parse(md.markdownToHtml(data['selftext'])).body.text)
                      .documentElement
                      .text
                      .replaceAll(RegExp(r"\s"), " ");
                  return parsed.substring(0, [200, parsed.length].reduce(min));
                })()
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
        actions: [
          StreamBuilder(
            stream: authBloc.streamProfileData,
            initialData: '',
            builder: (context, snapshot) {
              return Center(
                child: Text(snapshot.data.toString()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              authBloc.authRequestEventSink.add(AuthRequestEvent());
            },
          ),
        ],
      ),
      body: Container(color: Colors.black, child: Center(child: getBody())),
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

  Widget upVotePanel(int index) {
    return Container(
      width: 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.keyboard_arrow_up,
            color: Color.fromARGB(255, 255, 106, 50),
          ),
          Text(
            _posts[index]['upvotes'].toString(),
            style: TextStyle(color: Color.fromARGB(255, 255, 106, 50)),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: Color.fromARGB(255, 141, 168, 255),
          ),
        ],
      ),
    );
  }

  Widget contentPanel(int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) {
                return Scaffold(
                  body: Markdown(
                    data: _posts[index]['content'],
                    padding: EdgeInsets.fromLTRB(20, 50, 20, 50),
                  ),
                );
              },
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.only(right: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child: Text(
                  _posts[index]['title'],
                  textAlign: TextAlign.justify,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Container(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Text(
                    _posts[index]['short'],
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget getListTile(BuildContext context, int index) {
    return Container(
      padding: EdgeInsets.all(5),
      color: Color.fromARGB(255, 20, 20, 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            upVotePanel(index),
            contentPanel(index),
          ],
        ),
      ),
    );
  }

  Widget getBody() {
    if (_posts == null || _posts.length == 0)
      return CircularProgressIndicator();

    return Container(
        padding: EdgeInsets.only(top: 5),
        child: ListView.separated(
          itemBuilder: (context, index) => getListTile(context, index),
          separatorBuilder: (context, index) => Container(
                height: 5,
                color: Colors.black,
              ),
          itemCount: _posts?.length ?? 0,
        ));
  }

  @override
  void initState() {
    super.initState();
    fetch('hot');
  }
}
