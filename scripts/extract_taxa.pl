#!/usr/bin/perl

# Pragmas
use strict;
use warnings;

my %lib = ();
my $taxon_id = 1;

while (my $entry = <>) {
  chomp $entry;

  $entry =~ m/(\d+),"([^"]*)","([^"]*)"/;
  my ($organism_id, $species, $taxa) = ($1, $2, $3);

  my @taxa = map { s/'//; $_ } split(";", $taxa);

  $species =~ s/_/ /g;
  push @taxa, $species;

  for (my $i = 0; $i < scalar(@taxa); $i++) {
    my $taxon = $taxa[$i];
    my $parent = $taxa[$i-1];

    if (not defined $lib{$taxon}) {
      $lib{$taxon}->{ID} = $taxon_id++;
      $lib{$taxon}->{ORGANISMS} = [];
      $lib{$taxon}->{PARENTS} = [];
    }

    push @{$lib{$taxon}->{ORGANISMS}}, $organism_id;

    next if $i-1 < 0;

    push @{$lib{$taxon}->{PARENTS}}, $parent;
  }
}

# Print taxa.csv
# ===============
#
# Uncomment code and run on terminal:
# $ ./extract_taxa < organisms.csv > data/taxa.csv
#
# Import CSV on PostgreSQL:
# (requires mounting local dir with CSVs in container's path /csv)
# =# COPY taxa FROM '/csv/taxa.csv' DELIMITER ',' CSV;

# for my $taxon (sort { $lib{$a}->{ID} <=> $lib{$b}->{ID} } keys %lib) {
#   print "$lib{$taxon}->{ID},\"$taxon\"\n";
# }

# Print organisms_have_taxa.csv
# ==============================
#
# Uncomment code and run on terminal:
# $ ./extract_taxa < organisms.csv > data/organisms_have_taxa.csv
# $ sort -u -t, -k1,1n -k2,2n data/organisms_have_taxa.csv > data/organisms_have_taxa.csv2
# $ mv data/organisms_have_taxa.csv > data/organisms_have_taxa.csv2
#
# Import CSV on PostgreSQL:
# (requires mounting local dir with CSVs in container's path /csv)
# =# COPY organisms_have_taxa FROM '/csv/organisms_have_taxa.csv' DELIMITER ',' CSV;

# for my $taxon (sort { @{$lib{$a}->{ORGANISMS}} <=> @{$lib{$b}->{ORGANISMS}} } keys %lib) {
#   for my $organism_id (sort @{$lib{$taxon}->{ORGANISMS}}) {
#     print "$organism_id,$lib{$taxon}->{ID}\n";
#   }
# }

# Print taxa_have_taxa.csv
# =========================
#
# Uncomment code and run on terminal:
# $ ./extract_taxa < organisms.csv > data/taxa_have_taxa.csv
# $ sort -u -t, -k1,1n -k2,2n data/taxa_have_taxa.csv > data/taxa_have_taxa.csv2
# $ mv data/taxa_have_taxa.csv2 data/taxa_have_taxa.csv
#
# Import CSV on PostgreSQL:
# (requires mounting local dir with CSVs in container's path /csv)
# =# COPY taxa_have_taxa FROM '/csv/taxa_have_taxa.csv' DELIMITER ',' CSV;

for my $taxon (sort { $lib{$a}->{ID} <=> $lib{$b}->{ID} } keys %lib) {
  for my $parent (sort @{$lib{$taxon}->{PARENTS}}) {
    print "$lib{$parent}->{ID},$lib{$taxon}->{ID}\n";
  }
}
