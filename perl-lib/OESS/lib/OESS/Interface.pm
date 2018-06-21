#!/usr/bin/perl

use strict;
use warnings;

package OESS::Interface;

use OESS::DB::Interface;
use Data::Dumper;


sub new{
    my $that  = shift;
    my $class = ref($that) || $that;

    my $logger = Log::Log4perl->get_logger("OESS.Interface");

    my %args = (
        interface_id => undef,
        db => undef,
        @_
        );

    my $self = \%args;

    bless $self, $class;

    $self->{'logger'} = $logger;

    if(!defined($self->{'db'})){
        $self->{'logger'}->error("No Database Object specified");
        return;
    }

    $self->_fetch_from_db();

    return $self;
}

sub from_hash{
    my $self = shift;
    my $hash = shift;
    
    $self->{'name'} = $hash->{'name'};
    $self->{'interface_id'} = $hash->{'interface_id'};
    $self->{'node'} = $hash->{'node'};
    $self->{'description'} = $hash->{'description'};
    $self->{'operational_state'} = $hash->{'operational_state'};
    $self->{'acls'} = $hash->{'acls'};
    $self->{'mpls_vlan_tag_range'} = $hash->{'mpls_vlan_tag_range'};
    $self->_process_mpls_vlan_tag();

}

sub to_hash{
    my $self = shift;
    
    return { name => $self->name(),
             description => $self->description(),
             interface_id => $self->interface_id(),
             node_id => $self->node()->node_id(),
             node => $self->node()->name(),
             acls => $self->acls()->to_hash()
    };
}

sub _fetch_from_db{
    my $self = shift;


    if(!defined($self->{'interface_id'})){
        if(defined($self->{'name'}) && defined($self->{'node'})){
            my $interface_id = OESS::DB::Interface::get_interface(db => $self->{'db'}, interface => $self->{'name'}, node => $self->{'node'});
            if(!defined($interface_id)){
                $self->{'logger'}->error();
                return;
            }
            $self->{'interface_id'} = $interface_id;
        }
    }

    if(!defined($self->{'interface_id'})){
        $self->{'logger'}->error("Unable to find interface");
        return;
    }

    my $info = OESS::DB::Interface::fetch(db => $self->{'db'}, interface_id => $self->{'interface_id'});

    $self->from_hash($info);
}

sub update_db{
    my $self = shift;

}

sub interface_id{
    my $self = shift;
    return $self->{'interface_id'};
}

sub name{
    my $self = shift;
    return $self->{'name'};
}

sub description{
    my $self = shift;
    return $self->{'description'};
    
}

sub port_number{

}

sub operational_state{

}

sub acls{
    my $self = shift;
    return $self->{'acls'};
}

sub role{

}

sub node{
    my $self = shift;
    return $self->{'node'};
}

sub workgroup{
    
}

sub vlan_tag_range{

}

sub mpls_vlan_tag_range{
    my $self = shift;
    return $self->{'mpls_vlan_tag_range'};
}

sub vlan_in_use{
    my $self = shift;
    my $vlan = shift;

    #check and see if the specified VLAN tag is already in use
    
    my $in_use = OESS::DB::Interface::vrf_vlans_in_use(db => $self->{'db'}, interface_id => $self->interface_id() );
    
    push(@{$in_use},OESS::DB::Interface::circuit_vlans_in_use(db => $self->{'db'}, interface_id => $self->interface_id()));

    foreach my $used (@$in_use){
        if($used == $vlan){
            return 1;
        }
    }

    return 0;

}

sub _process_mpls_vlan_tag{
    my $self = shift;
    
    
    my %range;
    my @range = split(',',$self->mpls_vlan_tag_range());
    foreach my $range (@range){
        if($range =~ /-/){
            my ($start,$end) = split('-',$range);
            for(my $i=$start; $i<=$end;$i++){
                $range{$i} = 1;
            }
        }else{
            #single value
            $range{$range} = 1;
        }
    }
    $self->{'mpls_range'} = \%range;
}

sub mpls_range{
    my $self = shift;
    return $self->{'mpls_range'};
}

sub vlan_valid{
    my $self = shift;
    my %params = @_;
    my $vlan = $params{'vlan'};
    my $workgroup_id = $params{'workgroup_id'};

    #first check for valid range
    if($vlan < 1 || $vlan > 4095){
        return 0;
    }

    #first check and make sure the VLAN tag is not in use
    if($self->vlan_in_use($vlan)){
        return 0;
    }

    if(!$self->acls()->vlan_allowed( vlan => $vlan, workgroup_id => $workgroup_id)){
        return 0;
    }
    
    if(!defined($self->mpls_range()->{$vlan})){
        return 0;
    }

    #ok we got this far... its allowed
    return 1;
}

1;

