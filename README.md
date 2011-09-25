## Perl Starter -- A Cheap Kickstarter Clone

I love Kickstarter, but their Terms and Conditions limit the kinds of projects
you can run. I thought it might be interesting to experiment with other kinds
of projects but that required an application that could do what Kickstarter
does. This is the start of just such an application.


## Install

1) Download the [tarball][1] and extract it to a directory, finally change to the new directory.

>   wget https://github.com/Tamarou/PerlStarter/tarball/master
>   tar -xvzf PerlStarter.tar.gz
>   cd PerlStarter

2) Install the pre-requisites. You can do this with `cpanm -l perl5 [dist]`
where `[dist]` is each of the list below. This may take a little while.

    Dancer
    Dancer::Test
    DateTime
    Digest::SHA1
    ExtUtils::MakeMaker
    KiokuDB::Backend::DBI
    KiokuDB::Role::ID
    KiokuX::Model
    KiokuX::User
    KiokuX::User::Util
    List::Util
    Moose
    Plack
    Test::More
    Try::Tiny
    
3) Assuming you ran the command above, you can start the application using plackup. 

>    plackup -I perl5/lib/perl5
    
[1]: https://github.com/Tamarou/PerlStarter/tarball/master