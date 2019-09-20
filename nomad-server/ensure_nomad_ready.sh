while true; do
  echo "ensure nomad ready"
  nomad operator raft list-peers
  if [ $? -eq 0 ]; then
      break
  fi
done

while true; do
  echo "ensure leader standing"
  COUNT="$(nomad operator raft list-peers | grep leader | wc -l)"
  if [ "${COUNT}" = "1" ]; then
      break
  fi
done
