# See flake.nix (just-flake)
import 'just-flake.just'

# Display the list of recipes
default:
    @just --list
    @echo

# Add your custom recipes here
# Example:
# update-deps:
#     @echo "🔄 Updating dependencies..."
#     nix flake update 