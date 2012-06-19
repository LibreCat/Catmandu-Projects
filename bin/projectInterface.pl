#!/usr/bin/perl -w

use lib ("/home/bup/perl5/lib/perl5");

use Projects;
use Dancer;


get '/' => sub {
        redirect '/searchProjects/';
};

get '/showProject/:id' => sub {
        my $project = Projects::showProject(param('id'));
        
        if(!$project->{_id}){
                return "There exists no project with the given project ID.";
        }
        else {
                my $projectString = "Project splash page for project $project->{_id}.<br /><br />";
                
                $projectString .= "<b>_id:</b> " . $project->{_id};
                
                $projectString .= "<br /><b>name:</b> ";
                $projectString .= $project->{name} if $project->{name};
                
                $projectString .= "<br /><b>alternativeName:</b> ";
                $projectString .= $project->{alternativeName} if $project->{alternativeName};
                
                $projectString .= "<br /><b>description:</b> ";
                $projectString .= $project->{description} if $project->{description};
                
                $projectString .= "<br /><b>url:</b> ";
                $projectString .= $project->{url} if $project->{url};
                
                $projectString .= "<br /><b>startYear:</b> ";
                $projectString .= $project->{startYear} if $project->{startYear};
                
                $projectString .= "<br /><b>endYear:</b> ";
                $projectString .= $project->{endYear} if $project->{endYear};
                
                $projectString .= "<br /><b>isActive:</b> ";
                $projectString .= $project->{isActive} if $project->{isActive};
                
                $projectString .= "<br /><b>isFunded:</b> ";
                $projectString .= $project->{isFunded} if $project->{isFunded};
                
                $projectString .= "<br /><b>isGlobal:</b> ";
                $projectString .= $project->{isGlobal} if $project->{isGlobal};
                
                $projectString .= "<br /><b>isOwnedBy:</b> ";
                my $name;
                foreach (@{$project->{isOwnedBy}}){
                        if($name){
                                $name .= "<br />";
                        }
                        $name .= $_->{name}->{personTitle}." " if $_->{name}->{personTitle};
                        $name .= $_->{name}->{givenName}." ".$_->{name}->{surname};
                }
                $projectString .= $name if $name;
                
                $projectString .= "<br /><b>isOwnedByDepartment:</b> ";
                my $dept;
                foreach (@{$project->{isOwnedByDepartment}}){
                        if ($dept){
                                $dept .= "<br />";
                        }
                        $dept .= $_->{name};
                }
                $projectString .= $dept if $dept;
                
                $projectString .= "<br /><b>projectFunders:</b> ";
                my $fund;
                foreach (@{$project->{projectFunders}}){
                        if ($fund){
                                $fund .= "<br />";
                        }
                        $fund .= $_;
                }
                $projectString .= $fund if $fund;
                
                $projectString .= "<br /><b>grantNumber:</b> ";
                $projectString .= $project->{grantNumber} if $project->{grantNumber};
                
                $projectString .= "<br /><b>PSPElement:</b> ";
                $projectString .= $project->{pspElement}."<br />" if $project->{pspElement};
                
                $projectString .= "<br /><a href='/deleteProject/$project->{_id}'>Delete this project</a><br />";
                $projectString .= "<a href='/editProject/$project->{_id}'>Edit this project</a><br />";
                $projectString .= "<a href='/searchProjects/'>Back to search</a>";
                return $projectString;
        }
};

get '/searchProjects/:field/:value' => sub {
        my @records;
        @records = Projects::searchProjects(param('field'), param('value'));
        
        if(@records){
                my $returnRecords = "<h3>Search results</h3>"."\n";
                $returnRecords .= "<table border='1'><tr><td><b>ID</b></td><td><b>Name</b></td><td><b>Departments</b></td><td><b>Active?</b></td><td><b>Edit</b></td></tr>";
                foreach(@records){
                        $returnRecords .= "<tr>";
                        $returnRecords .= "<td>".$_->{_id}."</td>";
                        $returnRecords .= "<td><a href='/showProject/$_->{_id}'>".$_->{name}."</a></td>";
                        
                        $returnRecords .= "<td>";
                        foreach my $dep (@{$_->{isOwnedByDepartment}}){
                                $returnRecords .= $dep->{name}.",";
                        }
                        $returnRecords .= "</td>";
                        
                        $returnRecords .= "<td>".$_->{isActive}."</td>";
                        $returnRecords .= "<td><a href='/editProject/".$_->{_id}."'>edit</a></td>";
                        $returnRecords .= "</tr>";
                }
                $returnRecords .= "</table>";
        }
        else{
                return "No projects found for your search terms.";
        }
};

get '/searchProjects/' => sub {
        my @records;
        @records = Projects::searchProjects();
        
        if(@records){
                my $returnRecords = "<h3>Search results</h3>"."\n";
                $returnRecords .= "<table border='1'><tr><td><b>ID</b></td><td><b>Name</b></td><td><b>Departments</b></td><td><b>Active?</b></td><td><b>Edit</b></td></tr>";
                foreach(@records){
                        $returnRecords .= "<tr>";
                        $returnRecords .= "<td>".$_->{_id}."</td>";
                        $returnRecords .= "<td><a href='/showProject/$_->{_id}'>".$_->{name}."</a></td>";
                        
                        $returnRecords .= "<td>";
                        foreach my $dep (@{$_->{isOwnedByDepartment}}){
                                $returnRecords .= $dep->{name}.",";
                        }
                        $returnRecords .= "</td>";
                        
                        $returnRecords .= "<td>".$_->{isActive}."</td>";
                        $returnRecords .= "<td><a href='/editProject/".$_->{_id}."'>edit</a></td>";
                        $returnRecords .= "</tr>";
                }
                $returnRecords .= "</table>";
                
                $returnRecords .= "<a href='/editProject/new'>Create new project</a>";
        }
        else{
                return "No projects found.";
        }
};

get '/editProject/:id' => sub {
        if (param('id') eq 'new'){
                my $form;
                $form .= "<h3>New project</h3>";
                $form .= "<form action='/updateProject/' method='post'>";
                
                $form .= "<table><tr>";
                $form .= "<td>Name: </td><td><input type='text' size='73' name='name' id='name' value='' /></td></tr>";
                
                $form .= "<tr><td>alternativeName: </td><td><input type='text' size='73' name='alternativeName' id='alternativeName' value='' /></td></tr>";
                
                $form .= "<tr><td>description: </td><td><input type='text' size='73' name='description' id='description' value='' /></td></tr>";
                
                $form .= "<tr><td>isOwnedBy: </td><td></td></tr>";
                $form .= "<tr><td></td><td><input type='hidden' name='persId1' value='' /><input type='text' name='personTitle1' value='' placeholder='title' /><input type='text' name='givenName1' value='' placeholder='given name' /><input type='text' name='surname1' value='' placeholder='last name' /><input type='hidden' name='persNo' value='1' /></td></tr>";
                
                $form .= "<tr><td>startYear: </td><td><input type='text' size='4' maxlength='4' name='startYear' id='startYear' value='' /></td></tr>";
                $form .= "<tr><td>endYear: </td><td><input type='text' size='4' maxlength='4' name='endYear' id='endYear' value='' /></td></tr>";
                
                $form .= "<tr><td>isActive: </td><td><input type='radio' name='isActive' value='1'> Yes</input> &nbsp; <input type='radio' name='isActive' value='0' checked> No </input></td></tr>";
                $form .= "<tr><td>isFunded: </td><td><input type='radio' name='isFunded' value='1'> Yes</input> &nbsp; <input type='radio' name='isFunded' value='0' checked> No </input></td></tr>";
                
                $form .= "<tr><td>projectFunders: </td><td></td></tr>";
                $form .= "<tr><td></td><td><input type='text' size='73' name='projectFunders1' value='' /><input type='hidden' name='fundNo' value='1' /></td></tr>";
                
                $form .= "<tr><td>grantNumber: </td><td><input type='text' size='73' name='grantNumber' id='grantNumber' value='' /></td></tr>";
                
                $form .= "<tr><td>isGlobal: </td><td><input type='radio' name='isGlobal' value='1'> Yes</input> &nbsp; <input type='radio' name='isGlobal' value='0' checked> No </input></td></tr>";
                
                $form .= "<tr><td>isOwnedByDepartment: </td><td></td></tr>";
                $form .= "<tr><td></td><td><input type='hidden' name='deptId1' value='' /><input type='text' size='73' name='deptName1' value='' /><input type='hidden' name='deptNo' value='1' /></td></tr>";
                
                $form .= "<tr><td>pspElement: </td><td><input type='text' size='73' name='pspElement' id='pspElement' value='' /></td></tr>";
                
                $form .= "<tr><td>url: </td><td><input type='text' size='73' name='url' id='url' value='' /></td></tr>";
                
                $form .= "<td></td><td><input type='submit' name='submit' value='submit' /></td></tr>";
                
                $form .= "</table></form>";
        }
        else {
                my $project = Projects::showProject(param('id'));
                my $form;
                $form .= "<h3>Edit project $project->{_id}</h3>";
                $form .= "<form action='/updateProject/' method='post'>";
                $form .= "<input type='hidden' name='_id' id='_id' value='$project->{_id}' />";
                
                $form .= "<table><tr>";
                
                $form .= "<td>Name: </td><td><input type='text' size='73' name='name' id='name' value='$project->{name}' /></td></tr>";
                
                $form .= "<tr><td>alternativeName: </td><td><input type='text' size='73' name='alternativeName' id='alternativeName' value='";
                $form .= $project->{alternativeName} if $project->{alternativeName};
                $form .= "' /></td></tr>";
                
                $form .= "<tr><td>description: </td><td><input type='text' size='73' name='description' id='description' value='";
                $form .= $project->{description} if $project->{description};
                $form .= "' /></td></tr>";
                
                $form .= "<tr><td>isOwnedBy: </td><td></td></tr>";
                my $i = 1;
                foreach (@{$project->{isOwnedBy}}){
                        $form .= "<tr><td></td><td><input type='hidden' name='persId$i' value='$_->{persId}' /><input type='text' name='personTitle$i' value='$_->{name}->{personTitle}' placeholder='title' /><input type='text' name='givenName$i' value='$_->{name}->{givenName}' placeholder='given name' /><input type='text' name='surname$i' value='$_->{name}->{surname}' placeholder='last name' /></td></tr>";
                        $i++;
                }
                $form .= "<tr><td></td><td><input type='hidden' name='persId$i' value='' /><input type='text' name='persTitle$i' value='' placeholder='title' /><input type='text' name='givenName$i' value='' placeholder='given name' /><input type='text' name='surname$i' value='' placeholder='last name' /><input type='hidden' name='persNo' value='$i' /></td></tr>";
                
                $form .= "<tr><td>startYear: </td><td><input type='text' size='4' maxlength='4' name='startYear' id='startYear' value='$project->{startYear}' /></td></tr>";
                $form .= "<tr><td>endYear: </td><td><input type='text' size='4' maxlength='4' name='endYear' id='endYear' value='$project->{endYear}' /></td></tr>";
                
                my $isActive = ""; my $isNotActive = "checked";
                $isActive = "checked" if ($project->{isActive} && $project->{isActive} eq '1');
                $isNotActive = "" if $isActive eq "checked";
                $form .= "<tr><td>isActive: </td><td><input type='radio' name='isActive' value='1' $isActive > Yes</input> &nbsp; <input type='radio' name='isActive' value='0' $isNotActive > No </input></td></tr>";
                
                my $isFunded = ""; my $isNotFunded = "checked";
                $isFunded = "checked" if ($project->{isFunded} && $project->{isFunded} eq '1');
                $isNotFunded = "" if $isFunded eq "checked";
                $form .= "<tr><td>isFunded: </td><td><input type='radio' name='isFunded' value='1' $isFunded > Yes</input> &nbsp; <input type='radio' name='isFunded' value='0' $isNotFunded > No </input></td></tr>";
                
                $form .= "<tr><td>projectFunders: </td><td></td></tr>";
                $i = 1;
                foreach (@{$project->{projectFunders}}){
                        $form .= "<tr><td></td><td><input type='text' size='73' name='projectFunders$i' value='$_' /></td></tr>";
                        $i++;
                }
                $form .= "<tr><td></td><td><input type='text' size='73' name='projectFunder$i' value='' /><input type='hidden' name='fundNo' value='$i' /></td></tr>";
                
                $form .= "<tr><td>grantNumber: </td><td><input type='text' size='73' name='grantNumber' id='grantNumber' value='";
                $form .= $project->{grantNumber} if $project->{grantNumber};
                $form .= "' /></td></tr>";
                
                my $isGlobal = ""; my $isNotGlobal = "checked";
                $isGlobal = "checked" if ($project->{isGlobal} and $project->{isGlobal} eq '1');
                $isNotGlobal = "" if $isGlobal eq "checked";
                $form .= "<tr><td>isGlobal: </td><td><input type='radio' name='isGlobal' value='1' $isGlobal > Yes</input> &nbsp; <input type='radio' name='isGlobal' value='0' $isNotGlobal > No </input></td></tr>";
                
                $form .= "<tr><td>isOwnedByDepartment: </td><td></td></tr>";
                $i = 1;
                foreach (@{$project->{isOwnedByDepartment}}){
                        $form .= "<tr><td></td><td><input type='hidden' name='deptId$i' value='$_->{deptId}' /><input type='text' size='73' name='deptName$i' value='$_->{name}' /></td></tr>";
                        $i++;
                }
                $form .= "<tr><td></td><td><input type='hidden' name='deptId$i' value='' /><input type='text' size='73' name='deptName$i' value='' /><input type='hidden' name='deptNo' value='$i' /></td></tr>";
                
                $form .= "<tr><td>pspElement: </td><td><input type='text' size='73' name='pspElement' id='pspElement' value='$project->{pspElement}' /></td></tr>";
                
                $form .= "<tr><td>url: </td><td><input type='text' size='73' name='url' id='url' value='";
                $form .= $project->{url} if $project->{url};
                $form .= "' /></td></tr>";
                
                $form .= "<td></td><td><input type='submit' name='submit' value='submit' /></td></tr>";
                
                $form .= "</table></form>";
                
                $form .= "<a href='/deleteProject/$project->{_id}'>Delete this project</a><br />";
                $form .= "<a href='/searchProjects/'>Back to search</a>";
        }
};

post '/updateProject/' => sub {
        
    my $project_hash;
    $project_hash->{_id} = params->{_id} if params->{_id};
    $project_hash->{name} = params->{name} if params->{name};
    $project_hash->{alternativeName} = params->{alternativeName} if params->{alternativeName};
    $project_hash->{description} = params->{description} if params->{description};
    $project_hash->{url} = params->{url} if params->{url};
    $project_hash->{startYear} = params->{startYear} if params->{startYear};
    $project_hash->{endYear} = params->{endYear} if params->{endYear};
    $project_hash->{isActive} = params->{isActive};
    $project_hash->{isFunded} = params->{isFunded};
    $project_hash->{isGlobal} = params->{isGlobal};
    
    my $persNo = params->{persNo};
    for (my $i=1; $i<=$persNo; $i++){
        my $person = {};
        unless(params->{"givenName$i"} eq '' or params->{"surname$i"} eq ''){
                $person->{persId} = params->{"persId$i"} if params->{"persId$i"};
                $person->{name}->{personTitle} = params->{"personTitle$i"} if params->{"personTitle$i"};
                $person->{name}->{givenName} = params->{"givenName$i"} if params->{"givenName$i"};
                utf8::encode($person->{name}->{givenName});
                $person->{name}->{surname} = params->{"surname$i"} if params->{"surname$i"};
                utf8::encode($person->{name}->{surname});
                push @{$project_hash->{isOwnedBy}}, $person;
        }
    }
    
    my $deptNo = params->{deptNo};
    for (my $i=1; $i<=$deptNo; $i++){
        my $department = {};
        unless(params->{"deptName$i"} eq ''){
                $department->{deptId} = params->{"deptId$i"} if params->{"deptId$i"};
                $department->{name} = params->{"deptName$i"} if params->{"deptName$i"};
                push @{$project_hash->{isOwnedByDepartment}}, $department;
        }
    }

    my $fundNo = params->{fundNo};
    for (my $i=1; $i<=$fundNo; $i++){
        unless(params->{"projectFunder$i"} eq ''){
                push @{$project_hash->{projectFunders}}, params->{"projectFunder$i"};
        }
    }

    $project_hash->{grantNumber} = params->{grantNumber} if params->{grantNumber};
    $project_hash->{pspElement} = params->{pspElement} if params->{pspElement};
    
    my $added = Projects::updateProject($project_hash);
    
    redirect "/showProject/$project_hash->{_id}";
};

get '/deleteProject/:id' => sub {
        my $deleted = Projects::deleteProject(param('id'));
        redirect '/searchProjects/';
};

dance;