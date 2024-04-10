package ru.beeline.fdmauth.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.dto.role.RoleInfoDTO;

import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

import static ru.beeline.fdmauth.utils.Constant.DATE_FORMAT;
import static ru.beeline.fdmauth.utils.Constant.DATE_TIMEZONE;

@Getter
@Setter
@AllArgsConstructor
public class EmailResponseDTO {

    private String email;
}
