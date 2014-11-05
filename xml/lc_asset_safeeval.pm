# The LearningOnline Network with CAPA - LON-CAPA
# The Safe-Eval Space
#
# Copyright (C) 2014 Michigan State University Board of Trustees
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
package Apache::lc_asset_safeeval;

use strict;
use Safe();
use Safe::Hole();
use Math::Cephes();
use Math::Random();
use Opcode();


# ====
# Initialize a safespace
#
sub init_safe {

  my $safeeval = new Safe;
  my $safehole = new Safe::Hole;

# Cascading deny/permit

  $safeeval->permit_only(":default");
  $safeeval->permit(qw(entereval :base_math :base_loop sort time caller));
  $safeeval->deny(qw(rand srand :base_io :filesys_read :sys_db :filesys_write :dangerous));

# The evaluate function

  $safeeval->reval(<<'ENDEVALUATE');
sub evaluate {
  my ($expression)=@_;
  return $expression;
}
ENDEVALUATE

# Math::Cephes

  $safehole->wrap(\&Math::Cephes::asin,$safeeval,'&asin');
  $safehole->wrap(\&Math::Cephes::acos,$safeeval,'&acos');
  $safehole->wrap(\&Math::Cephes::atan,$safeeval,'&atan');
  $safehole->wrap(\&Math::Cephes::sinh,$safeeval,'&sinh');
  $safehole->wrap(\&Math::Cephes::cosh,$safeeval,'&cosh');
  $safehole->wrap(\&Math::Cephes::tanh,$safeeval,'&tanh');
  $safehole->wrap(\&Math::Cephes::asinh,$safeeval,'&asinh');
  $safehole->wrap(\&Math::Cephes::acosh,$safeeval,'&acosh');
  $safehole->wrap(\&Math::Cephes::atanh,$safeeval,'&atanh');
  $safehole->wrap(\&Math::Cephes::erf,$safeeval,'&erf');
  $safehole->wrap(\&Math::Cephes::erfc,$safeeval,'&erfc');
  $safehole->wrap(\&Math::Cephes::j0,$safeeval,'&j0');
  $safehole->wrap(\&Math::Cephes::j1,$safeeval,'&j1');
  $safehole->wrap(\&Math::Cephes::jn,$safeeval,'&jn');
  $safehole->wrap(\&Math::Cephes::jv,$safeeval,'&jv');
  $safehole->wrap(\&Math::Cephes::y0,$safeeval,'&y0');
  $safehole->wrap(\&Math::Cephes::y1,$safeeval,'&y1');
  $safehole->wrap(\&Math::Cephes::yn,$safeeval,'&yn');
  $safehole->wrap(\&Math::Cephes::yv,$safeeval,'&yv');
  
  $safehole->wrap(\&Math::Cephes::bdtr  ,$safeeval,'&bdtr'  );
  $safehole->wrap(\&Math::Cephes::bdtrc ,$safeeval,'&bdtrc' );
  $safehole->wrap(\&Math::Cephes::bdtri ,$safeeval,'&bdtri' );
  $safehole->wrap(\&Math::Cephes::btdtr ,$safeeval,'&btdtr' );
  $safehole->wrap(\&Math::Cephes::chdtr ,$safeeval,'&chdtr' );
  $safehole->wrap(\&Math::Cephes::chdtrc,$safeeval,'&chdtrc');
  $safehole->wrap(\&Math::Cephes::chdtri,$safeeval,'&chdtri');
  $safehole->wrap(\&Math::Cephes::fdtr  ,$safeeval,'&fdtr'  );
  $safehole->wrap(\&Math::Cephes::fdtrc ,$safeeval,'&fdtrc' );
  $safehole->wrap(\&Math::Cephes::fdtri ,$safeeval,'&fdtri' );
  $safehole->wrap(\&Math::Cephes::gdtr  ,$safeeval,'&gdtr'  );
  $safehole->wrap(\&Math::Cephes::gdtrc ,$safeeval,'&gdtrc' );
  $safehole->wrap(\&Math::Cephes::nbdtr ,$safeeval,'&nbdtr' );
  $safehole->wrap(\&Math::Cephes::nbdtrc,$safeeval,'&nbdtrc');
  $safehole->wrap(\&Math::Cephes::nbdtri,$safeeval,'&nbdtri');
  $safehole->wrap(\&Math::Cephes::ndtr  ,$safeeval,'&ndtr'  );
  $safehole->wrap(\&Math::Cephes::ndtri ,$safeeval,'&ndtri' );
  $safehole->wrap(\&Math::Cephes::pdtr  ,$safeeval,'&pdtr'  );
  $safehole->wrap(\&Math::Cephes::pdtrc ,$safeeval,'&pdtrc' );
  $safehole->wrap(\&Math::Cephes::pdtri ,$safeeval,'&pdtri' );
  $safehole->wrap(\&Math::Cephes::stdtr ,$safeeval,'&stdtr' );
  $safehole->wrap(\&Math::Cephes::stdtri,$safeeval,'&stdtri');

# Math::Cephes::Matrix

  $safehole->wrap(\&Math::Cephes::Matrix::mat,$safeeval,'&mat');
  $safehole->wrap(\&Math::Cephes::Matrix::new,$safeeval,'&Math::Cephes::Matrix::new');
  $safehole->wrap(\&Math::Cephes::Matrix::coef,$safeeval,'&Math::Cephes::Matrix::coef');
  $safehole->wrap(\&Math::Cephes::Matrix::clr,$safeeval,'&Math::Cephes::Matrix::clr');
  $safehole->wrap(\&Math::Cephes::Matrix::add,$safeeval,'&Math::Cephes::Matrix::add');
  $safehole->wrap(\&Math::Cephes::Matrix::sub,$safeeval,'&Math::Cephes::Matrix::sub');
  $safehole->wrap(\&Math::Cephes::Matrix::mul,$safeeval,'&Math::Cephes::Matrix::mul');
  $safehole->wrap(\&Math::Cephes::Matrix::div,$safeeval,'&Math::Cephes::Matrix::div');
  $safehole->wrap(\&Math::Cephes::Matrix::inv,$safeeval,'&Math::Cephes::Matrix::inv');
  $safehole->wrap(\&Math::Cephes::Matrix::transp,$safeeval,'&Math::Cephes::Matrix::transp');
  $safehole->wrap(\&Math::Cephes::Matrix::simq,$safeeval,'&Math::Cephes::Matrix::simq');
  $safehole->wrap(\&Math::Cephes::Matrix::mat_to_vec,$safeeval,'&Math::Cephes::Matrix::mat_to_vec');
  $safehole->wrap(\&Math::Cephes::Matrix::vec_to_mat,$safeeval,'&Math::Cephes::Matrix::vec_to_mat');
  $safehole->wrap(\&Math::Cephes::Matrix::check,$safeeval,'&Math::Cephes::Matrix::check');
  $safehole->wrap(\&Math::Cephes::Matrix::check,$safeeval,'&Math::Cephes::Matrix::check');

# Math::Random

  $safehole->wrap(\&Math::Random::random_beta,$safeeval,'&math_random_beta');
  $safehole->wrap(\&Math::Random::random_chi_square,$safeeval,'&math_random_chi_square');
  $safehole->wrap(\&Math::Random::random_exponential,$safeeval,'&math_random_exponential');
  $safehole->wrap(\&Math::Random::random_f,$safeeval,'&math_random_f');
  $safehole->wrap(\&Math::Random::random_gamma,$safeeval,'&math_random_gamma');
  $safehole->wrap(\&Math::Random::random_multivariate_normal,$safeeval,'&math_random_multivariate_normal');
  $safehole->wrap(\&Math::Random::random_multinomial,$safeeval,'&math_random_multinomial');
  $safehole->wrap(\&Math::Random::random_noncentral_chi_square,$safeeval,'&math_random_noncentral_chi_square');
  $safehole->wrap(\&Math::Random::random_noncentral_f,$safeeval,'&math_random_noncentral_f');
  $safehole->wrap(\&Math::Random::random_normal,$safeeval,'&math_random_normal');
  $safehole->wrap(\&Math::Random::random_permutation,$safeeval,'&math_random_permutation');
  $safehole->wrap(\&Math::Random::random_permuted_index,$safeeval,'&math_random_permuted_index');
  $safehole->wrap(\&Math::Random::random_uniform,$safeeval,'&math_random_uniform');
  $safehole->wrap(\&Math::Random::random_poisson,$safeeval,'&math_random_poisson');
  $safehole->wrap(\&Math::Random::random_uniform_integer,$safeeval,'&math_random_uniform_integer');
  $safehole->wrap(\&Math::Random::random_negative_binomial,$safeeval,'&math_random_negative_binomial');
  $safehole->wrap(\&Math::Random::random_binomial,$safeeval,'&math_random_binomial');
  $safehole->wrap(\&Math::Random::random_seed_from_phrase,$safeeval,'&random_seed_from_phrase');
  $safehole->wrap(\&Math::Random::random_set_seed_from_phrase,$safeeval,'&random_set_seed_from_phrase');
  $safehole->wrap(\&Math::Random::random_get_seed,$safeeval,'&random_get_seed');
  $safehole->wrap(\&Math::Random::random_set_seed,$safeeval,'&random_set_seed');

  return $safeeval;
}

#
# Returns a snippet of text with variables evaluated
#
sub texteval {
   my ($safeeval,$text)=@_;
#FIXME: Debug
my   $result=$safeeval->reval(qq(&evaluate(q($text))));
use Apache::lc_logs;
use Data::Dumper;
&logdebug("Text: $text: ".Dumper($result));
return $result;
}

#
# Executes code inside of safeeval
#
sub codeeval {
   my ($safeeval,$code)=@_;
   return $safeeval->reval($code);
}

1;
__END__
