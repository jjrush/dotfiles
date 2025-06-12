#!/bin/bash

backup_dotfiles() {
    local dotfiles_dir="$HOME/dotfiles"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local target_dir="$dotfiles_dir/macos"
        echo "Detected macOS - backing up zsh files to $target_dir"
        
        mkdir -p "$target_dir"
        
        if [[ -f "$HOME/.zshrc" ]]; then
            mv "$HOME/.zshrc" "$target_dir/zshrc"
            echo "Moved .zshrc to $target_dir/zshrc"
        fi
        
        if [[ -f "$HOME/.zsh_aliases" ]]; then
            mv "$HOME/.zsh_aliases" "$target_dir/zsh_aliases"
            echo "Moved .zsh_aliases to $target_dir/zsh_aliases"
        fi
        
        if [[ -f "$HOME/.zsh_func" ]]; then
            mv "$HOME/.zsh_func" "$target_dir/zsh_func"
            echo "Moved .zsh_func to $target_dir/zsh_func"
        fi
        
    else
        local target_dir="$dotfiles_dir/linux"
        echo "Detected Linux - backing up bash files to $target_dir"
        
        mkdir -p "$target_dir"
        
        if [[ -f "$HOME/.bashrc" ]]; then
            mv "$HOME/.bashrc" "$target_dir/bashrc"
            echo "Moved .bashrc to $target_dir/bashrc"
        fi
        
        if [[ -f "$HOME/.bash_aliases" ]]; then
            mv "$HOME/.bash_aliases" "$target_dir/bash_aliases"
            echo "Moved .bash_aliases to $target_dir/bash_aliases"
        fi
        
        if [[ -f "$HOME/.bash_func" ]]; then
            mv "$HOME/.bash_func" "$target_dir/bash_func"
            echo "Moved .bash_func to $target_dir/bash_func"
        fi
    fi
    
    echo "Backup completed!"
}

restore_dotfiles() {
    local dotfiles_dir="$HOME/dotfiles"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local source_dir="$dotfiles_dir/macos"
        echo "Detected macOS - restoring zsh files from $source_dir"
        
        if [[ -f "$source_dir/zshrc" ]]; then
            cp "$source_dir/zshrc" "$HOME/.zshrc"
            echo "Restored $source_dir/zshrc to ~/.zshrc"
        fi
        
        if [[ -f "$source_dir/zsh_aliases" ]]; then
            cp "$source_dir/zsh_aliases" "$HOME/.zsh_aliases"
            echo "Restored $source_dir/zsh_aliases to ~/.zsh_aliases"
        fi
        
        if [[ -f "$source_dir/zsh_func" ]]; then
            cp "$source_dir/zsh_func" "$HOME/.zsh_func"
            echo "Restored $source_dir/zsh_func to ~/.zsh_func"
        fi
        
    else
        local source_dir="$dotfiles_dir/linux"
        echo "Detected Linux - restoring bash files from $source_dir"
        
        if [[ -f "$source_dir/bashrc" ]]; then
            cp "$source_dir/bashrc" "$HOME/.bashrc"
            echo "Restored $source_dir/bashrc to ~/.bashrc"
        fi
        
        if [[ -f "$source_dir/bash_aliases" ]]; then
            cp "$source_dir/bash_aliases" "$HOME/.bash_aliases"
            echo "Restored $source_dir/bash_aliases to ~/.bash_aliases"
        fi
        
        if [[ -f "$source_dir/bash_func" ]]; then
            cp "$source_dir/bash_func" "$HOME/.bash_func"
            echo "Restored $source_dir/bash_func to ~/.bash_func"
        fi
    fi
    
    echo "Restore completed!"
}