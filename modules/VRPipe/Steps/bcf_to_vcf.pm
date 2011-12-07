use VRPipe::Base;

class VRPipe::Steps::bcf_to_vcf with VRPipe::StepRole {
    method options_definition {
        return { bcftools_exe => VRPipe::StepOption->get(description => 'path to bcftools executable',
                                                         optional => 1,
                                                         default_value => 'bcftools'),
                 bcftools_view_options => VRPipe::StepOption->get(description => 'bcftools view options',
                                                          optional => 1,
                                                          default_value => '-gcv') }; # from SNPS.pm
    }
    method inputs_definition {
        return { bcf_files => VRPipe::StepIODefinition->get(type => 'bin', max_files => -1, description => '1 or more bcf files to convert to compressed vcf') };
    }

    method body_sub {
        return sub {
            my $self = shift;
            my $options = $self->options;
            my $bcftools = $options->{bcftools_exe};
            my $view_opts = $options->{bcftools_view_options};
            
            my $req = $self->new_requirements(memory => 500, time => 1);
            foreach my $bcf (@{$self->inputs->{bcf_files}}) {

                my $bcf_path = $bcf->path;
				my $basename = $bcf->basename;
				$basename =~ s/bcf$/vcf.gz/;
                my $vcf_file = $self->output_file(output_key => 'vcf_files', basename => $basename, type => 'vcf');
                my $vcf_path = $vcf_file->path;

                my $cmd = qq[$bcftools view $view_opts $bcf_path | bgzip -c > $vcf_path];
                $self->dispatch([$cmd, $req, {output_files => [$vcf_file]}]); 
            }
        };
    }
    method outputs_definition {
        return { vcf_files => VRPipe::StepIODefinition->get(type => 'bin', max_files => -1, description => 'a .vcf.gz file for each input bcf file') };
    }
    method post_process_sub {
        return sub { return 1; };
    }
    method description {
        return "Run bcftools view option to generate one compressed vcf file per input bcf";
    }
    method max_simultaneous {
        return 0; # meaning unlimited
    }
}

1;