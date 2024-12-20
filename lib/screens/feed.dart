import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/miniflux.dart';
import '../models/data_all.dart';
import '../models/feed.dart';

// Create a Form widget for update and delete
class MyFeedForm extends StatefulWidget {
  MyFeedForm({Key? key, required this.feed}) : super(key: key);
  final Feed feed;

  @override
  MyFeedFormState createState() {
    return MyFeedFormState(feed: feed);
  }
}

class MyFeedFormState extends State<MyFeedForm> {
  MyFeedFormState({Key? key, required this.feed});
  final Feed feed;

  final _formKey = GlobalKey<FormState>();
  String? _feedUrl;
  String? _siteUrl;
  String? _title;
  int? _categoryId;
  String? _scraperRules;
  String? _rewriteRules;
  bool? _crawler;
  String? _username;
  String? _password;
  String? _userAgent;

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  // Load preferences
  void _loadValues() {
    setState(() {
      _feedUrl = feed.feedUrl;
      _siteUrl = feed.siteUrl;
      _title = feed.title;
      _categoryId = feed.category!.id;
      _scraperRules = feed.scraperRules;
      _rewriteRules = feed.rewriteRules;
      _crawler = feed.crawler;
      _username = feed.userName;
      _password = feed.password;
      _userAgent = feed.userAgent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataAll = Provider.of<DataAll>(context, listen: false);
    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(labelText: 'Title'),
                onSaved: (val) {
                  setState(() => _title = val);
                },
                validator: (val) {
                  if (val!.isEmpty) {
                    return 'Please enter the title';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _siteUrl,
                decoration: InputDecoration(labelText: 'Site URL'),
                keyboardType: TextInputType.url,
                onSaved: (val) {
                  setState(() => _siteUrl = val);
                },
                validator: (val) {
                  if (val!.isEmpty) {
                    return 'Please enter the site URL';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _feedUrl,
                decoration: InputDecoration(labelText: 'Feed URL *'),
                keyboardType: TextInputType.url,
                onSaved: (val) {
                  setState(() => _feedUrl = val);
                },
                validator: (val) {
                  if (val!.isEmpty) {
                    return 'The feed URL is mandatory';
                  } else if (!val
                      .toLowerCase()
                      .startsWith(new RegExp(r'^https?://'))) {
                    return 'The URL must start with \'http(s)://\'';
                  }
                  return null;
                },
              ),
              TextFormField(
                initialValue: _username,
                decoration: InputDecoration(labelText: 'Feed Username'),
                onSaved: (val) {
                  setState(() => _username = val);
                },
              ),
              TextFormField(
                initialValue: _password,
                decoration: InputDecoration(labelText: 'Feed Password'),
                obscureText: true,
                onSaved: (val) {
                  setState(() => _password = val);
                },
              ),
              TextFormField(
                initialValue: _userAgent,
                decoration:
                    InputDecoration(labelText: 'Override Default User Agent'),
                onSaved: (val) {
                  setState(() => _userAgent = val);
                },
              ),
              TextFormField(
                initialValue: _scraperRules,
                decoration: InputDecoration(labelText: 'Scraper Rules'),
                onSaved: (val) {
                  setState(() => _scraperRules = val);
                },
              ),
              TextFormField(
                initialValue: _rewriteRules,
                decoration: InputDecoration(labelText: 'Rewrite Rules'),
                onSaved: (val) {
                  setState(() => _rewriteRules = val);
                },
              ),
              DropdownButtonFormField(
                value: _categoryId,
                items: dataAll.categories
                    .map((category) => DropdownMenuItem(
                          child: Text(category!.title!),
                          value: category.id,
                        ))
                    .toList(),
                decoration: InputDecoration(labelText: 'Category *'),
                validator: (dynamic val) {
                  if (val == null) {
                    return 'The category is mandatory';
                  }
                  return null;
                },
                onChanged: (dynamic value) {
                  setState(() => _categoryId = value);
                },
              ),
              DropdownButtonFormField(
                value: _crawler,
                items: [
                  DropdownMenuItem(child: Text('Yes'), value: true),
                  DropdownMenuItem(child: Text('No'), value: false),
                ],
                decoration:
                    InputDecoration(labelText: 'Fetch original content'),
                onChanged: (dynamic value) {
                  setState(() => _crawler = value);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Container(
                  child: Row(
                    children: <Widget>[
                      ElevatedButton(
                        child: Text('Save'),
                        onPressed: () async {
                          final FormState form = _formKey.currentState!;
                          if (form.validate()) {
                            form.save();
                            Map<String, dynamic> params = {
                              'feed_url': _feedUrl,
                              'site_url': _siteUrl,
                              'title': _title,
                              'category_id': _categoryId,
                              'scraper_rules': _scraperRules,
                              'rewrite_rules': _rewriteRules,
                              'crawler': _crawler,
                              'username': _username,
                              'password': _password,
                              'user_agent': _userAgent,
                            };
                            try {
                              await updateFeed(feed.id, params);
                              dataAll.refresh();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Changes saved!')));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('An error occured!\n$e')));
                            }
                          }
                        },
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      new ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              Theme.of(context).colorScheme.error),
                        ),
                        child: Text(
                          'Delete',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .titleLarge!
                                  .color),
                        ),
                        onPressed: () async {
                          try {
                            await removeFeed(feed.id);
                            dataAll.refresh();
                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('An error occured!\n$e')));
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Feed feed = ModalRoute.of(context)!.settings.arguments as Feed;
    return Scaffold(
      appBar: AppBar(title: Text(feed.title!)),
      body: MyFeedForm(feed: feed),
    );
  }
}
