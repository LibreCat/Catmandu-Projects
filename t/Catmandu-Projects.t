# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Catmandu-Projects.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::Simple tests => 6;
use Catmandu::Projects;

#########################

# Test 1: 
my $record = Catmandu::Projects::showProject("P1");
ok ($record->{_id} eq "P1", "showProject(P1)");

# Test 2:
my @records = Catmandu::Projects::searchProjects();
ok (@records, "searchProjects()");

# Test 3:
@records = Catmandu::Projects::searchProjects("pspElement", "D-3210-zzzz-yxyx-0007");
ok ($records[0]->{name} eq "Consequences of entering test project data into mongo databases and the positive influence of CPAN, gitHub and Perl on the stress level of developers in part time captivity.", "searchProjects(pspElement, D-3210-zzzz-yxyx-0007)");

# Test 4:
my $newRecord = {
          '_id' => '',
          'isActive' => '0',
          'startYear' => '2007',
          'name' => "Neu angelegtes Testprojekt3",
          'isOwnedByDepartment' => [
                                     {
                                       'deptId' => 'depId01',
                                       'name' => 'depName01'
                                     }
                                   ],
          'isInProjectListFor' => [
                                    {
                                      'deptId' => 'depId01',
                                      'name' => 'depName01'
                                    }
                                  ],
          'isOwnedBy' => [
                           {
                             'name' => {
                                         'fullName' => 'Marc Renee',
                                         'personTitle' => 'Dr.',
                                         'givenName' => 'Marc',
                                         'surname' => 'Renee'
                                       }
                           }
                         ],
          'pspElement' => 'D-3210-abab-0008-xyxy',
          'endYear' => '2009'
        };

my $result = Catmandu::Projects::updateProject($newRecord);
ok ($result =~ /Created\/updated project P.*/, "updateProject(newRecord) -> added a new record to the database, created a new ID!");

# Test 5:
my $existingRecord = {
          '_id' => 'P1',
          'isActive' => '0',
          'startYear' => '2007',
          'name' => "Verändertes Testprojekt",
          'isOwnedByDepartment' => [
                                     {
                                       'deptId' => 'depId01',
                                       'name' => 'depName01'
                                     }
                                   ],
          'isInProjectListFor' => [
                                    {
                                      'deptId' => 'depId01',
                                      'name' => 'depName01'
                                    }
                                  ],
          'isOwnedBy' => [
                           {
                             'name' => {
                                         'fullName' => 'Max Mustermann',
                                         'personTitle' => 'Dr.',
                                         'givenName' => 'Max',
                                         'surname' => 'Mustermann'
                                       }
                           }
                         ],
          'pspElement' => 'D-3210-abab-0080-xyxy',
          'endYear' => '2009'
        };

$result = Catmandu::Projects::updateProject($existingRecord);
ok ($result =~ /Created\/updated project P.*/, "updateProject(existingRecord) -> changed an existing record in the database!");

# Test 6:
$result = Catmandu::Projects::deleteProject("P1");
ok ($result =~ /Deleted project P.*/, "deleteProject(P1)");
