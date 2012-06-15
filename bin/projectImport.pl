#!/usr/bin/perl -w

use lib qw(../../lib/extension ../../lib/default);
use lib ("/home/bup/perl5/lib/perl5");

use Data::Dumper;
use Text::CSV;
use Projects;

use Utilities;
use utf8;

use Catmandu::Store::MongoDB;
my $store = Catmandu::Store::MongoDB->new(database_name => 'Projects');

my $file = shift;
unless ($file) {
    print STDERR "Please enter a file name."."\n";
    exit(1);
}


my $csv = Text::CSV->new({binary => 1}) or die "Cannot use CSV: ".Text::CSV->error_diag();
open my $fh, "<:encoding(utf8)", $file or die "$file: $!";

my $departmentIdMap = {
    '01' => 'depId01',
    '02' => 'depId02',
    # extend this mapping according to local ids
};

my $departmentNameMap = {
    'depId01' => 'depName01',
    'depId02' => 'depName02',
    # extend this mapping according to local department names
};

#####################################
### Format for import file (csv):
###
### The order of the columns is CRUCIAL here!
### "PSP-Element", "principal investigator", "endDate", "startDate", "department", "title"
###
### Additional columns are okay, IF they are appended after "title"
###
#####################################

while (my $row = $csv->getline($fh)){
    my $pi; my $enddate; my $startdate; my $dept; my $departments; my $title; my $description;
    my $extFund = "nein"; my $mitarbeiter; my $funder; my $laufzeit = ""; my $isActive = 0; my $projectOIds; my $url;
	
    ###
    # Assigning values to variables
    my $pspElement = $row->[0];
	
    my @verantwortliche = split /;/, $row->[1];
    foreach (@verantwortliche){
        $_ =~ s/^\s+|\s+$//g;
        push @{$pi}, $_;
    }

    $enddate = $row->[2];
    $startdate = $row->[3];

    $dept = $departmentIdMap->{$row->[4]};
    push @{$departments}, $dept;
	
    $title = $row->[5];
	
	
    ###
    # process startdate and enddate
    # currently only years are used
    my $startyear = 0; my $startmonth = 0; my $startday = 0;
    if ($startdate =~ /(\d{2})\.(\d{2})\.(\d{4})/){
        $startday = int($1);
        $startmonth = int($2);
        $startyear = int($3);
    }
    my $endyear = 0;
    if ($enddate =~ /\.(\d{4})/){
        $endyear = int($1);
    }

    ###
    # isActive
    my @timeData = localtime(time);
    my $currentYear = 1900 + int($timeData[5]);
    if ($startyear!=0 && $endyear!=0){
        if(($startyear)<= $currentYear && ($endyear)>= $currentYear){
            $isActive = 1;
        }
    }
    elsif($startyear !=0){
        if(($startyear)<= $currentYear){
            $isActive = 1;
        }
    }
    elsif($endyear !=0){
        if(($endyear)>= $currentYear){
            $isActive = 1;
        }
    }
	
	
    ###
    # Check if a project with this pspElement already exists
    # duplicate control
    my @projects;
    if($pspElement){
        @projects = $store->bag->getByFieldValue("pspElement", $pspElement);
    }
    if(@projects){
        # If a project with this pspElement already exists, check if you can update it
        print "Project with pspElement $pspElement already exists. Skipping."."\n";
        #foreach (@projects){
            # TODO: add update functionality for existing projects
            # Until then, this loop prevents the script from creating duplicate projects.
        #}
    }
	
    # If no project with this pspElement exists, create a new one
    else {
        my $id = "";
        $id = Projects::autoId();
        if ( !$id ) {
            warn "--> Couldn't create ID for project"."\n";
            exit;
        }
		
        my $mongo_hash;
		
        $mongo_hash->{_id} = $id;
        $mongo_hash->{pspElement} = $pspElement if $pspElement;
        $mongo_hash->{name} = $title if $title;
        $mongo_hash->{isActive} = "$isActive";
        $mongo_hash->{description} = $description if $description;
        $mongo_hash->{startYear} = "$startyear" if $startyear;
        $mongo_hash->{endYear} = "$endyear" if $endyear;
        
        # Set departments the project belongs to
        foreach my $deptId (@{$departments}){
            my $dept_name = $departmentNameMap->{$deptId};
            my $ownDep;
            $ownDep->{deptId} = $deptId;
            $ownDep->{name} = $dept_name;
            push @{$mongo_hash->{isOwnedByDepartment}}, $ownDep;
            push @{$mongo_hash->{isInProjectListFor}}, $ownDep;
        }
        
        
        # Set people the project belongs to (principle investigator)
        foreach my $projectOwner (@{$pi}){
            my ($title, $forename, $lastname) = &_manageNames($projectOwner);
            $title =~ s/^\s+|\s+$//g;
            $forename =~ s/^\s+|\s+$//g;
            $lastname =~ s/^\s+|\s+$//g;
                                            
            my $fullName = $forename." ".$lastname;
            $fullName = $title." ".$fullName if $title;

            my $persDetail;
            $persDetail->{name} = {personTitle => $title,
				     givenName => $forename,
				       surname => $lastname,
				      fullName => $fullName,
            };
            push @{$mongo_hash->{isOwnedBy}}, $persDetail;
        }
        
        $store->bag->add($mongo_hash);
        
        ###
        # Unfortunately the following sleep(1) command is necessary, even though it slows down
        # the import process considerably.
        # MongoDB - guess: the database index? - seems to be too slow (or the import script is too
        # quick), so that sometimes the writing/indexing process has not yet been finished when the
        # next import loop starts and autoId checks for ids again. This results in autoId not finding
        # the newest id, creating the same ID again and thus import overwrites a record in the database.
        #
        # If the database gets bigger and records are overwritten, this sleep time probably needs to
        # be set to a higher value.
        sleep(1);
        
        # Print confirmation of successful work
        print "Created new project with ID $id."."\n";
    }

}

$csv->eof or $csv->error_diag();
close $fh;

sub _manageNames {
	
    ###
    # This sub was originally designed to manage different (German) name formats. But since these formats
    # only appeared in one specific database that's no longer in use with this module, most of its functionality
    # was removed, reducing the sub to split first from last names.
    # Works only with "lastname, firstname(s)" format

    my $projectOwner = "";
    $projectOwner = $_[0];
    if($projectOwner ne ""){
        my $forename = ""; my $lastname = ""; my $title = "";
        if($projectOwner =~ /,/){
            ($lastname, $forename) = split /,/, $projectOwner;
            $forename =~ s/^\s+|\s+$//g;
            $lastname =~ s/^\s+|\s+$//g;
            $projectOwner = "";
        }
		
        return ($title, $forename, $lastname);
    }
    else {
        return ("", "", "");
    }

}
