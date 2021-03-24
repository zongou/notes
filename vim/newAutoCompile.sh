
apt install -y git make libncurses5-dev libncurses5 checkinstall

cd ~/
git clone https://gitee.com/zongou/vim

cd ~/vim
./configure --with-features=huge \
  --enable-multibyte \
  --enable-gui=false \
  --enable-cscope 
make -j8

checkinstall -y

#apt remove -y vim vim-runtime gvim
#apt remove -y vim-tiny vim-common vim-gui-common vim-nox
#rm -rf /usr/share/vim
# install
dpkg -i --force-overwrite vim*.deb

# Make vim default editor
editor=$(which vim)
	update-alternatives --install /usr/bin/editor editor $editor 1
	update-alternatives --set editor $editor
	update-alternatives --install /usr/bin/vi vi $editor 1
	update-alternatives --set vi $editor

