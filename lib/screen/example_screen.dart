import 'package:flutter/material.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';

class ExampleScreen extends StatefulWidget {
  static const routeName = '/ExampleScreen';

  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey,
      appBar: AppBar(
        // title: const SelectableText('Privacy Policy'),
        backgroundColor: Colors.white,
        shadowColor: Colors.black,
      ),
      body: body(),
    );
  }

  Widget body() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 100),
        child: BootstrapContainer(
          fluid: true,
          children: [
            BootstrapRow(
              height: 0,
              children: <BootstrapCol>[
                BootstrapCol(
                  sizes: 'col-xm-12 col-sm-12 col-md-1 col-lg-2 col-xl-2',
                  child: Container(),
                ),
                BootstrapCol(
                  sizes: 'col-xm-12 col-sm-12 col-md-10 col-lg-8 col-xl-8',
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Your Body',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                BootstrapCol(
                  sizes: 'col-xm-12 col-sm-12 col-md-1 col-lg-2 col-xl-2',
                  child: Container(),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
// THIS IS HOW YOU CALL A METHOD FOR AN API
// ApiResult response =
//           await Provider.of<HttpService>(context, listen: false)
//               .post(ApiNames.loginUser, _signUpModel.toJson());