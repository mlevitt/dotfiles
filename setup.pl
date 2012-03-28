#!/usr/bin/perl


    use strict;
    use warnings;

    use Cwd 'abs_path';
    use File::Basename;
    # an improved version of 'use FindBin'
    BEGIN {$FindBin::Bin = dirname( abs_path $0 );}

    use File::Find;

    use Data::Dumper;
    $Data::Dumper::Useqq++;
    use Devel::Comments;           # uncomment this during development to enable the ### debugging statements


(my $repository_dir = $FindBin::Bin) =~ s/^\Q$ENV{HOME}\E/~/;

chdir $FindBin::Bin;


# run through all files/directories under ~/dotfiles/
find { wanted => sub {
    s/^\.\///;

    # directories to avoid altogether
    if ($_ eq '.git') {
        $File::Find::prune++;
        return;
    }

    # files to not symlink
    return if ($_ eq '.');
    return if ($_ eq 'setup.pl');
    return if /(?:^|\/)README.(?:creole|md)$/;
    return if /\.swp$/;
    
    if (-d $_) {
        # if it's a directory, create that path under $HOME
        do_mkdir($_);

    } elsif (-f $_) {
        # if it's a file, symlink it to $HOME
        if (/\.subst$/) {
            do_substitute($_);
        } else {
            do_symlink($_);
        }
    }
}, no_chdir=>1}, ".";


if ($ENV{USER} =~ /^[p][h][r][8][4][3]$/) {
    # in some cases, I want to make sure the checkin attribution is correct
    system "git", "config", "user.name", "Dee Newcum";
    system "git", "config", "user.email", 'dee.newcum@gmail.com';
}



sub do_mkdir {
    my ($dir) = @_;

    return if (-d "$ENV{HOME}/$dir");

    if (-e "$ENV{HOME}/$dir" && !-d "$ENV{HOME}/$dir") {
        print "ERROR: Unable to create directory '$dir' because something is in the way.\n";
        return;
    }

    system "mkdir", "-p", "$ENV{HOME}/$dir";

    if (-d "$ENV{HOME}/$dir") {
        #print "created   $dir\n";
        print "setup    ~/$dir\n";
    } else {
        print "ERROR: unable to create directory '$dir'\n";
    }
}


sub do_symlink {
    my ($file) = @_;

    my $to   = "$ENV{HOME}/$file";
    my $from = "$FindBin::Bin/$file";

    if (! -e $to) {
        symlink $from, $to;
        #print "creating symlink    $from     to    $to\n";
        print "setup    ~/$file\n";
    } else {
        # The file already exists.  Now what?
        if (-l $to) {
            if (readlink($to) ne $from) {
                # Change the symlink to point to our version.
                unlink $to;
                symlink $from, $to;
                #print "creating symlink    $from     to    $to\n";
                print "setup    ~/$file\n";
            }
        } else {
            # It's a regular file.
            # Is it one of the files we know about, that we can suggest a #include/source line to the user?
            if (!scan_file_for_include_command($file)) {
                # If the above function returned false, that means it didn't notify the user about the status of the file.  So we'll use the fallback notification.
                print "WARNING: ~/$file  already exists\n";
            }
            # If it returned true, then it either decided that no error was needed, or it decided an error was needed, and it printed it.
        }
    }
}


# Specific file types have the ability to '#include' or 'source' another file.
# 
# Here we scan through the file, line-by-line, checking if it has the specific command we're looking for.
#
# Returns true if this routine took care of notifying the user.
sub scan_file_for_include_command {
    my ($file) = @_;

    my %include_commands = map {s/^\s+|\s+$//sg; $_} split /[\n\r]+/, <<'EOF';
        .bash_aliases
                [ -f ${STDIN_OWNERS_HOME:-~}/<<HOMEPATH>> ] && source ${STDIN_OWNERS_HOME:-~}/<<HOMEPATH>>
        .bashrc
                [ -f <<PATH>> ] && source <<PATH>>
        .sudo_bashrc
                [ -f $STDIN_OWNERS_HOME/<<HOMEPATH>> ] && source $STDIN_OWNERS_HOME/<<HOMEPATH>>
        .vimrc
                exec "source " . expand('<sfile>:p:h') . "/<<HOMEPATH>>"
EOF
    #.vimrc =>    source <<PATH>>
    #print Dumper \%include_commands; exit;

    return 0 unless (-e "$ENV{HOME}/$file");
    return 0 unless (exists $include_commands{$file});

    my $home_path = "$ENV{HOME}/$file";
    my $repo_path = "$FindBin::Bin/$file";

    my $lookingfor = $include_commands{$file};
    my $lookingfor_path = $repo_path;
    my $HOME = Cwd::abs_path($ENV{HOME});
    $lookingfor_path =~ s/^\Q$HOME\E/~/;
    $lookingfor =~ s/<<PATH>>/$lookingfor_path/g;
    if ($lookingfor =~ /<<HOMEPATH>>/) {
        my $lookingfor_homepath = $lookingfor_path;
        if ($lookingfor_homepath =~ s#^~/##) {
            $lookingfor =~ s/<<HOMEPATH>>/$lookingfor_homepath/g;
        } else {
            # It's impossible to use <<HOMEPATH>> in this case, because the $repo_path isn't anywhere under $ENV{HOME}
            # So show them the fallback error message.
            return 0;
        }
    }

    open my $fin, "<", $home_path       or die $!;
    while (<$fin>) {
        s/^\s+|\s+$//gs;        # chomp & trim
        if ($_ eq $lookingfor) {
            # the user has the desired #include/source command here... so all is well....  no error message needed
            return 1;
        }
    }
    close $fin;

    print "WARNING: ~/$file   already exists.  If you want to have local tailorings, insert this somewhere:\n\t$lookingfor\n";
    return 1;
}


sub do_substitute {
    my ($subst_filename) = @_;

    (my $subst_filename_basename = $subst_filename) =~ s/\.subst$//;

    my @subst_contents = slurp($subst_filename);

            # "active" means the version of the config file that is directly used by the standard tools
    my $active_filename = "$ENV{HOME}/$subst_filename_basename";

    my @active_old_contents = slurp($active_filename);

            # We include our repository directory here, because we want to be able to have multiple dotfile repositories on the same machine,
            # and have multipl repos substituting their text into different locations within the active file.
    my $header_text = "######## MODIFICATIONS HERE WILL BE OVERWRITTEN BY .subst FILE IN: $repository_dir/ ########";
    my $footer_text = "######## END SUBSTITUTION FROM: $repository_dir/ ########";

    # do we know where to insert it?
    if (!grep(/\Q$header_text\E/, @active_old_contents)) {
        print "WARNING: you need to insert this line into ~/$subst_filename_basename\nto be able to pull in the contents of $repository_dir/$subst_filename:\n\n\t$header_text\n\n(insert it as a comment, using whatever comment syntax is appropriate)\n";
        return;
    }

    # remove the existing text, if any
            # (existing text is anything between the header and footer...  if there is no 0
    my @active_new_contents = @active_old_contents;
    my $header_index = grep_index(qr/\Q$header_text\E/, @active_new_contents);
    my $footer_index = grep_index(qr/\Q$footer_text\E/, @active_new_contents);
        #$header_index = '(undef)' unless defined($header_index); $footer_index = '(undef)' unless defined($footer_index); print "header = $header_index\nfooter = $footer_index\n"; exit;
    if (defined($footer_index)) {
        splice(@active_new_contents, $header_index+1, $footer_index - $header_index);
    }
        #print Dumper \@active_new_contents; exit;

    # insert the new text
    (my $comment_prefix = $active_new_contents[$header_index])      # every file type uses different comment syntax
            =~ s/\Q$header_text\E.*//s;
    chomp $comment_prefix;
        #print ">>$comment_prefix<<\n"; exit;
    splice(@active_new_contents, $header_index+1, 0,   @subst_contents, "$comment_prefix$footer_text\n");
        #print Dumper \@active_new_contents; exit;

    # only write the data out if we actually changed something
    if (join("", @active_old_contents) ne join("", @active_new_contents)) {
        print "setup    ~/$subst_filename_basename\n";
        open my $fout, '>', $active_filename        or die "Unable to write to $active_filename:  $!";
        print $fout @active_new_contents;
        close $fout;
    }
}



# Return the index of the first array element that matches the given pattern.
#
# It would be nice to use List::Utils::first_index instead, but we can't guarantee that will be installed on every machine.
sub grep_index {
    my ($pattern, @ary) = @_;
    for (my $ctr=0; $ctr<=$#ary; $ctr++) {
        if ($ary[$ctr] =~ $pattern) {
            return $ctr;
        }
    }
    return undef;
}


# quickly read a whole file
sub slurp {my$p=open(my$f,"$_[0]")or die$!;my@o=<$f>;close$f;waitpid($p,0);wantarray?@o:join("",@o)}
