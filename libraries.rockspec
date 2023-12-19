package = "J3nstersVerificationBot"
version = "1.0-1"
source = {
   url = "https://github.com/j3nster/J3nsters-Verification-Bot/archive/master.zip",
}

dependencies = {
   "luarocks-fetch-git-file >= 1.0",
   "luasocket >= 3.0",
   "discordia >= 3.0",
}

build = {
   type = "builtin",
   modules = {
      ["mybot"] = "Program.lua",
   },
}
