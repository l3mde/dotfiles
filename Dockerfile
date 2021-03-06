FROM archlinux:latest
RUN set -x && pacman --noconfirm -Syu \
&& pacman --noconfirm -S vim htop tmux bash bash-completion zsh zsh-completions python base-devel git cmake go \
&& pacman --noconfirm -Scc \
&& useradd -s /usr/bin/zsh -m -b /home l3m
COPY . /opt/dotfiles
USER l3m
WORKDIR /home/l3m
RUN /opt/dotfiles/dotdrop -p terminal install -a
RUN /usr/bin/zsh -c ycm-enable
CMD ["/usr/bin/zsh"]
