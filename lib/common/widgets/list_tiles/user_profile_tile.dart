import 'package:flutter/material.dart';
import '../../../foundation/constants/colors.dart';
import '../images/t_circular_image.dart';

class TUserProfileTile extends StatelessWidget {
  const TUserProfileTile({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircularImage(
        applyOverlayColor: false,
        image: "TImages.user",
        width: 50,
        height: 50,
        padding: 0,
      ),
      title: Text("Mudassar Naeem", style: Theme.of(context).textTheme.headlineSmall!.apply(color: TColors.white),),
      subtitle: Text("bazurgIndustries@gmail.com", style: Theme.of(context).textTheme.bodyMedium!.apply(color: TColors.white),),
      trailing: IconButton(onPressed: onPressed, icon: Icon(Icons.edit, color: TColors.white,)),
    );
  }
}
