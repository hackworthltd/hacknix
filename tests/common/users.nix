{ ... }:

{
  users.users.alice = {
    isNormalUser = true;
    description = "Alice Test User";
    password = "ecila";
  };

  users.users.bob = {
    isNormalUser = true;
    description = "Bob Test User";
    password = "bob";
  };

}
