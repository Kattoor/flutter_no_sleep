import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Nosleep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.indigoAccent,
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

  void fetchHot() {
    get('https://www.reddit.com/r/nosleep/hot.json').then((response) {
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
      body: Center(
          child: ListView.separated(
        itemBuilder: (context, index) => ListTile(
              title: Text(_posts[index]['title']),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => Scaffold(
                        body: Markdown(
                            data: _posts[index]['content'],
                            padding: EdgeInsets.fromLTRB(20, 50, 20, 50))),
                  ),
                );
              },
            ),
        separatorBuilder: (context, index) => Divider(),
        itemCount: _posts?.length ?? 0,
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchHot,
        tooltip: 'Hot',
        child: Icon(Icons.add),
      ),
    );
  }
}
