import 'package:ecommerce_flutter/src/domain/models/User.dart';
import 'package:flutter/material.dart';

class ProfileInfoContent extends StatelessWidget {

  User? user;

  ProfileInfoContent(this.user);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _imageBackground(context),
        Column(
          children: [
            _imageProfile(),
            Spacer(),
            _cardProfileInfo(context)
          ],
        )
      ],
    );
  }

  Widget _cardProfileInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.46,
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        )
      ),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            ListTile(
              title: Text('${user?.name ?? ''} ${user?.lastname ?? ''}'),
              subtitle: Text('Nombre de usuario'),
              leading: Icon(Icons.person),
            ),
            ListTile(
              title: Text(user?.email ?? ''),
              subtitle: Text('Correo electronico'),
              leading: Icon(Icons.email),
            ),
            ListTile(
              title: Text(user?.phone ?? ''),
              subtitle: Text('Telefono'),
              leading: Icon(Icons.phone),
            ),
            Container(
              alignment: Alignment.centerRight,
              margin: EdgeInsets.only(right: 10),
              child: FloatingActionButton(
                backgroundColor: Colors.black,
                onPressed: () {
                  Navigator.pushNamed(context, 'profile/update', arguments: user);
                },
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
              ),
            ),
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.privacy_tip_outlined, size: 16, color: Colors.black54),
                  label: Text('Privacidad', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  onPressed: () => Navigator.pushNamed(
                    context, 'legal',
                    arguments: {'type': 'privacy', 'title': 'Política de Privacidad'},
                  ),
                ),
                SizedBox(width: 8),
                Text('·', style: TextStyle(color: Colors.black38)),
                SizedBox(width: 8),
                TextButton.icon(
                  icon: Icon(Icons.description_outlined, size: 16, color: Colors.black54),
                  label: Text('Términos', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  onPressed: () => Navigator.pushNamed(
                    context, 'legal',
                    arguments: {'type': 'terms', 'title': 'Términos y Condiciones'},
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _imageProfile() {
    return Container(
      margin: EdgeInsets.only(top: 100),
      width: 150,
      child: AspectRatio(
        aspectRatio: 1/1,
        child: ClipOval(
          child: user != null 
          ? user!.image != null 
           ? FadeInImage.assetNetwork(
              placeholder: 'assets/img/user_image.png', 
              image: user!.image!,
              fit: BoxFit.cover,
              fadeInDuration: Duration(seconds: 1),
            )
            : Image.asset(
                'assets/img/user_image.png',
              )
          :Image.asset(
              'assets/img/user_image.png',
          ),
        ),
      ),
    ); 
  }

  Widget _imageBackground(BuildContext context) {
    return Image.asset(
      'assets/img/background1.jpg',
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      fit: BoxFit.cover,
      color: Color.fromRGBO(0, 0, 0, 0.7),
      colorBlendMode: BlendMode.darken,
    );
  }
}