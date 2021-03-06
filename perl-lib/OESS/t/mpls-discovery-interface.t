#!/usr/bin/perl -T

use strict;

use FindBin;
my $path;

BEGIN {
    if($FindBin::Bin =~ /(.*)/){
            $path = $1;
      }
}

use lib "$path";
use OESS::Database;
use OESS::MPLS::Discovery::Interface;

use OESSDatabaseTester;

use Test::More tests => 7;
use Test::Deep;
use Data::Dumper;


my $db = OESS::Database->new( config => OESSDatabaseTester::getConfigFilePath() );

ok(defined($db), "OESS Database was created");

sub callback{
    #verify callback is called
}

my $interface_discovery = OESS::MPLS::Discovery::Interface->new( db => $db,
								 
    );

my $example_node = "Node 1";
my $example_data = [{
            'name' => 'e1/1',
            'description' => 'e1/1',
            'admin_state' => 'up',
            'operational_state' => 'down'
          },
          {
            'name' => 'e1/2',
            'description' => 'e1/2',
            'admin_state' => 'up',
            'operational_state' => 'down'
          },
          {
            'name' => 'e15/2',
            'description' => 'e15/2',
            'admin_state' => 'up',
            'operational_state' => 'down'
          }];

my $res = $interface_discovery->process_results( node => $example_node, interfaces => $example_data );

ok($res == 1, "Interface processing reports success");

my @results;
foreach my $intf (@$example_data) {
    my $intf_id = $db->get_interface_id_by_names(
	node => $example_node,
	interface => $intf->{'name'}
	);
    my $result = $db->get_interface(interface_id => $intf_id);
    if ($result->{'operational_state'} eq $intf->{'operational_state'}) {
	push(@results, "ok");
    }
}
ok(scalar @results == 3, "DB matches test data");

@$example_data[0]->{'name'} = "e10/10";
@$example_data[0]->{'description'} = "e10/10";
$interface_discovery->process_results( node => $example_node, interfaces => $example_data );
my $intf_id = $db->get_interface_id_by_names(
    node => $example_node,
    interface => @$example_data[0]->{'name'}
    );
$res = $db->get_interface(interface_id => $intf_id);
ok($res->{'name'} eq @$example_data[0]->{'name'}, "added interface name correct");
ok($res->{'description'} eq @$example_data[0]->{'description'}, "added interface description correct");
ok($res->{'operational_state'} eq @$example_data[0]->{'operational_state'}, "added interface operational state correct");

@$example_data[0]->{'operational_state'} = "up";
$res = $interface_discovery->process_results(node => $example_node, interfaces => $example_data);
$intf_id = $db->get_interface_id_by_names(
    node => $example_node,
    interface => @$example_data[0]->{'name'}
    );
$res = $db->get_interface(interface_id => $intf_id);
ok($res->{'operational_state'} eq "up", "operational state set to up");
