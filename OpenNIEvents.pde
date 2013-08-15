//OpenNI basic user events
void onNewUser(int userId){
  println("detected" + userId);
  user = userId;
}
void onLostUser(int userId){
  println("lost: " + userId);
  user = 0;
}

