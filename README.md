# RAID
Задание:
Добавить в Vagrantfile еще дисков
Собрать R0/R5/R10 на выбор
Прописать собранный рейд в конф, чтобы рейд собирался при загрузке
Сломать/починить raid
Создать GPT раздел и 5 партиций и смонтировать их на диск

1. Добавляем в Vagrant файл диски. Загружаемся. Для работы с рейдом устанавливаем программу mdadm
yum install -y mdadm smartmontools hdparm gdisk

2. Собироем рейд предворительно занулив суперблоки
mdadm --zero-superblock --force /dev/sd{b,c,d,e}
mdadm --create --verbose /dev/md0 --level=5 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde

3. создаем папку с файлом конфигурации для сбора рейда при загрузки и записываем в него конфигурацию
mkdir /etc/mdadm && touch /etc/mdadm/mdadm.conf
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

4. Ломаем
Для этого фэйлим диск mdadm /dev/md0 --fail /dev/sde
Получаем 
         Personalities : [raid6] [raid5] [raid4] 
         md0 : active raid5 sdc[1] sdb[0] sde[4](F) sdd[2]
         761856 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/3] [UUU_] 
         
  Чиним
Для этого удаляем сломанный диск из массива mdadm /dev/md0 --remove /dev/sde
Подключаем новый диск mdadm /dev/md0 --add /dev/sde
Ждем восстановления
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sde[4] sdc[1] sdb[0] sdd[2]
      761856 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/3] [UUU_]
      [=============>.......]  recovery = 69.6% (177628/253952) finish=0.0min speed=35525K/sec
      
  Починили
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sde[4] sdc[1] sdb[0] sdd[2]
      761856 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/4] [UUUU]

5. Создаем GPT раздел, 5 портиций и монтируем их на диск
parted -s /dev/md0 mklabel gpt
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done


* Доп. задание - Vagrantfile_RAID, которýй сразу собирает систему с подключенным рейдом.
