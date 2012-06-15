package Catmandu::Projects;

use strict;
use Catmandu::Store::MongoDB;
my $store = Catmandu::Store::MongoDB->new(database_name => 'Projects');

our $VERSION = '0.01';

=head1

showProject($id)
Takes string $id as parameter, returns a hash of ONE record (with the given ID)
Can be used to display project splash pages or display a single project for editing.

=cut

sub showProject {
    my $id = shift;
    my $rec = $store->bag->get($id);
	
    return $rec;
}

=head1

updateProject($record_hash)
Takes a hash of ONE record as parameter, returns success message string

First checks $record_hash for an ID.
CASE ID exists:
  -> record already existed and may now have been modified
  finds the corresponding record in the DB, deletes it and writes $record_hash in its place (with same ID as before)
CASE no ID exists:
  -> new record
  creates a new ID with the autoId function
  enters the new ID into the $record_hash in the field _id
  creates a new project with the $record_hash in the DB
  
=cut

sub updateProject {
    my $record = shift;
    my $id = $record->{_id};
    my $added;
    my $ok;
    if($id){
        my $deleted = $store->bag->delete($id);
        $added = $store->bag->add($record);
    }
    else {
        $id = autoId();
        if(!$id){
            warn "Could not create ID, please contact your system admin!"."\n";
            exit;
        }
        else {
            $record->{_id} = $id;
            $added = $store->bag->add($record);
        }
    }

    $ok = "Created/updated project $id" if $added;
    return $ok;
}

=head1

searchProjects($field, $searchTerm)
Takes string $field (name of the field to be searched in) and string $searchTerm, returns array of record hashes.

CASE no $searchTerm:
  returns array of ALL records in the DB (currently no pagination)
CASE $searchTerm and $field:
  returns array of all records where $field has the value $searchTerm

Always returns an array, even when the result is only one record hash!

=cut

sub searchProjects {
    my ($searchField, $searchTerm) = @_;
    my @records;
    if (!$searchTerm){
        @records = $store->bag->getAll();
    }
    else {
        @records = $store->bag->getByFieldValue($searchField, $searchTerm);
    }
	
    return @records;
}

=head1

deleteProject($id)
Takes string $id as parameter, returns success message string or undef on failure.

Checks if a record with the given $id exists and deletes it.
Returns success message if a record was deleted, undef otherwise.

=cut

sub deleteProject {
    my $id = shift;
    my $deleted;
    my $ok;
    if($id){
        my $rec = $store->bag->get($id);
        if($rec){
            $deleted = $store->bag->delete($id);
        }
    }
    $ok = "Deleted project $id" if $deleted;
    return $ok;
}

=head1

autoId()
Takes no parameters, returns $id string.

Gets the _id field of every record in the DB, compares IDs to find the one with the highest value.
Sets a new ID to the next higher value.
Returns a new $id.

=cut

sub autoId {
    my @ids = $store->bag->selectField("_id");
    my $id;
    my @newIds;
    foreach (@ids){
        $_->{_id} =~ s/^P//g;
        push @newIds, $_->{_id};
    }
    @newIds = sort {$a <=> $b} @newIds;
    my $idsLength = @newIds;
    $id = $newIds[$idsLength-1];
    $id++;
	
    my $newId = "P".$id;
    return $newId;
}

1;
__END__
=head1 NAME

Catmandu::Projects - Perl module for Catmandu that allows the maintenance of a mongoDB with project data.

=head1 SYNOPSIS

  use Catmandu::Projects;

=head1 DESCRIPTION

This module handles a mongo project DB. It provides routines for searching, viewing single projects,
editing and deleting projects. As well as a function to automatically generate consecutive project IDs.

The module requires the Catmandu framework and the (currently separate) Catmandu::Store::MongoDB module.

=head1 SEE ALSO

Catmandu on Cpan http://search.cpan.org/~nics/Catmandu-0.0106/
Catmandu on gitHub https://github.com/LibreCat/Catmandu
Catmandu::Store::MongoDB on gitHub https://github.com/LibreCat/Catmandu-Store-MongoDB

Perl MongoDB http://search.cpan.org/~kristina/MongoDB-0.45/lib/MongoDB.pm
Perl MongoDB subroutines in more detail: http://search.cpan.org/~kristina/MongoDB-0.45/lib/MongoDB/Collection.pm

=head1 AUTHOR

P. Kohorst, E<lt>petra.kohorst@uni-bielefeld.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by P. Kohorst

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
